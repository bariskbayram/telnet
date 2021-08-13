require 'socket'
require 'timeout'
require 'net/protocol'
require 'logger'

module Telnet
  class Client

    def initialize(args)
      @options = Hash.new
      @logger = Logger.new(STDOUT)
      if args.size < 2
        @logger.info "At least 2 arguments have to be given, hostname and port."
        exit
      end
      @options["host"] = args[0]
      @options["port"] = args[1]
      @options["timeout"] = args[2]
      if args[2].nil?
        @options["timeout"] = "10"
      end
      @logger.info "Client started"
    end

    def start
      begin
        Timeout.timeout(Integer(@options["timeout"]), Net::OpenTimeout) do
          @socket = TCPSocket.open(@options["host"], @options["port"])
        end
      rescue Net::OpenTimeout
        @logger.error "Time is up!"
        exit
      end

      @logger.info "Connected to #{@options["host"]}:#{@options["port"]}"

      response = 0
      while response != "200"
        @logger.info "Enter valid credential for connection."
        response = login
      end
      @logger.info "SUCCESS !"

      command = ""
      while command != "-1"
        command = get_user_command
        @socket.puts(command)
        @logger.info "Server said that => #{@socket.gets.chomp}"
      end
      @logger.info "Connection is closed !"
    end

    def login
      print "Username: "
      username = STDIN.gets.chomp
      print "Password: "
      password = STDIN.gets.chomp

      @socket.puts("#{username},#{password}")
      @socket.gets.chomp
    end

    def get_user_command
      print "Command: "
      STDIN.gets.chomp
    end

  end
end
