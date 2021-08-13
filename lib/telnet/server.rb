require 'socket'
require 'logger'

module Telnet
  class Server

    USERNAME = "admin"
    PASSWORD = "password"

    def initialize(host="127.0.0.1", port)
      @tcp_server = TCPServer.new(host, port)
      @client_sockets = []
      @logger = Logger.new(STDOUT)
    end

    def serve
      @logger.info "Server started on #{@tcp_server.local_address.ip_address}:#{@tcp_server.local_address.ip_port}"

      loop do
        Thread.new(@tcp_server.accept) do |socket|
          @client_sockets << socket
          @logger.info "Request is accepted. - #{socket.object_id}. Currently active sockets count: #{@client_sockets.size}"

          username, password = socket.gets.chomp.split(",")

          while username != USERNAME || password != PASSWORD
            @logger.info "Username or password error"
            socket.puts(401)
            username, password = socket.gets.chomp.split(",")
          end

          @logger.info "Successfully authenticated for #{socket.object_id}."
          socket.puts(200)

          request = ""
          while request != "-1"
            request = socket.gets.chomp
            socket.puts("#{request} to you, too !")
          end
          close_socket socket
        end
      end
    end

    def close_socket(socket)
      socket.close
      @client_sockets.delete(socket)
      @logger.info "#{socket.object_id} is closed."
    end

  end
end
