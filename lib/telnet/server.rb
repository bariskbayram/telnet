# frozen_string_literal: true

require "socket"
require "logger"
require "timeout"

module Telnet
  class ActiveClient
    attr_accessor :is_alive, :socket
    attr_reader :thread, :client_id

    def initialize(socket, thread)
      @client_id = socket.fileno
      @socket = socket
      @thread = thread
      @is_alive = true
    end
  end

  class Server
    USERNAME = "admin"
    PASSWORD = "password"

    def initialize(host = "127.0.0.1", port = "4242")
      @tcp_server = TCPServer.new(host, port)
      @clients = {}
      @mutex = Mutex.new
      @logger = Logger.new($stdout)
    end

    def get_clients
      @mutex.synchronize do
        @clients
      end
    end

    def synchronize(&block)
      @mutex.synchronize do
        block.call
      end
    end

    def serve
      @logger.info("Server started on #{@tcp_server.local_address.ip_address}:#{@tcp_server.local_address.ip_port}")

      loop do
        socket = @tcp_server.accept

        puts @clients.inspect

        session_client = check_session_alive(socket)
        if session_client.nil?
          Thread.new do
            client = ActiveClient.new(socket, Thread.current)
            synchronize { @clients[socket.fileno.to_s] = client }

            @logger.info("Request is accepted. - #{client.client_id}. Currently active sockets count: #{get_clients.size}")

            check_authentication client

            request = get_data(client)
            puts request

            loop do
              response = ""
              begin
                Timeout.timeout(30) do
                  response = `#{request}`
                end
              rescue Errno::ENOENT
                response = "#{request}: command not found...\n"
              rescue Timeout::Error
                response = "Time is up!\n"
              end
              response += "#{USERNAME} ~]$ "
              print response
              send_data(client.socket, response)

              request = get_data(client)
              puts request
            end

            send_data(client.socket, "403 #{USERNAME} ~]$ ")
            close_socket(client)
          end
        else
          @logger.info("#{session_client.client_id} is resuming...")
          session_client.thread.wakeup
          session_client.socket = socket
        end
      end
    end

    def check_session_alive(socket)
      data = get_data(ActiveClient.new(socket, Thread.current))
      response = "SESSION_CREATE"
      all_clients = get_clients

      if data.include?("SRESUME") && all_clients.size.positive?
        client_no = data.split(",")[0]
        if all_clients[client_no] && !all_clients[client_no].is_alive
          client = all_clients[data.split(",")[0]]
          client.is_alive = true
          response = "SESSION_RESUME"
        end
      end
      send_data(socket, "#{response} #{USERNAME} ~]$ ")
      client
    end

    def check_authentication(client)
      username, password = get_data(client).split(",")
      login_count = 2

      while username != USERNAME || password != PASSWORD
        if login_count.zero?
          send_data(client.socket, "403 #{USERNAME} ~]$ ")
          @logger.info("Authentication failed for 3 times.")
          close_socket(client)
        end
        @logger.info("Authentication failed.")
        send_data(client.socket, "401 #{USERNAME} ~]$ ")
        username, password = get_data(client).split(",")
        login_count -= 1
      end

      @logger.info("Successfully authenticated for #{client.client_id}.")
      send_data(client.socket, "200 #{USERNAME} ~]$ ")
      print("#{USERNAME} ~]$ ")
    end

    def get_data(client)
      unless client.socket.wait_readable(30)
        @logger.info("Time is up!")
        close_socket(client)
      end
      data = client.socket.gets.chomp
      if data.include?("SSTOP")
        @logger.info("#{client.client_id} is stopped.")
        client.is_alive = false
        Thread.stop
        data = "echo -n"
      elsif data.include?("SKILL")
        close_socket(client)
      end
      data
    rescue NoMethodError
      close_socket(client)
    end

    def send_data(socket, message)
      socket.puts(message) unless socket.closed?
    end

    def close_socket(client)
      synchronize { @clients.delete(client.client_id.to_s) }
      @logger.info("#{client.client_id} is closed.")
      client.socket.close
      Thread.current.kill
    end
  end
end
