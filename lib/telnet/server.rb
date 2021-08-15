require 'socket'
require 'logger'

module Telnet

  class ActiveClient

    attr_accessor :connection_status
    attr_reader :socket

    def initialize(socket)
      @socket = socket
      @connection_status = :active_connection
    end

  end

  class Server

    USERNAME = "admin"
    PASSWORD = "password"

    def initialize(host="127.0.0.1", port)
      @tcp_server = TCPServer.new(host, port)
      @clients = []
      @logger = Logger.new(STDOUT)
    end

    def serve
      @logger.info "Server started on #{@tcp_server.local_address.ip_address}:#{@tcp_server.local_address.ip_port}"

      loop do
        Thread.new(@tcp_server.accept) do |socket|
          client = ActiveClient::new(socket)
          @clients << client
          @logger.info "Request is accepted. - #{client.object_id}. Currently active sockets count: #{@clients.size}"

          check_authentication client.socket

          request = get_data(client)
          puts request
          while request != "-1"
            begin
              response = %x(#{request})
            rescue Errno::ENOENT
              response = "#{request}: command not found...\n"
            end
            response += "#{USERNAME} ~]$ "
            print response
            send_data(client.socket, response)

            request = get_data(client)
            puts request
          end
          send_data(client.socket, "403 #{USERNAME} ~]$ ")
          close_socket client
        end
      end
    end

    def check_authentication(client)
      username, password = get_data(client).split(",")
      login_count = 2

      while username != USERNAME || password != PASSWORD
        if login_count == 0
          send_data(client.socket, "403 #{USERNAME} ~]$ ")
          @logger.info "Username or password error"
          close_socket client
        end
        @logger.info "Username or password error"
        send_data(client.socket, "401 #{USERNAME} ~]$ ")
        username, password = get_data(client).split(",")
        login_count -= 1
      end

      @logger.info "Successfully authenticated for #{client.object_id}."
      send_data(client.socket, "200 #{USERNAME} ~]$ ")
      print "#{USERNAME} ~]$ "
    end

    def get_data(client)
      begin
        client.socket.gets.chomp
      rescue NoMethodError
        close_socket client
      end
    end

    def send_data(socket, message)
      unless socket.closed?
        socket.puts(message)
      end
    end

    def close_socket(client)
      client.socket.close
      @clients.delete(client.socket)
      @logger.info "#{client.object_id} is closed."
      Thread.current.kill
    end

  end
end
