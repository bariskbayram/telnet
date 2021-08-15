require 'socket'
require 'timeout'
require 'net/protocol'
require 'logger'

module Telnet
  class Client

    def initialize(options)
      @options = options
      @logger = Logger.new(STDOUT)
      @options["host"] = "localhost" if @options["host"].nil?
      @options["port"] = 23 if @options["port"].nil?
      @options["timeout"] = 10 if @options["timeout"].nil?
      @options["waittime"] = 10 if @options["waittime"].nil?
      @options["prompt"] = "~]$"
      @logger.info "Client started"
    end

    def start
      begin
        Timeout.timeout(Integer(@options["timeout"]), Net::OpenTimeout) do
          @socket = TCPSocket.open(@options["host"], @options["port"])
        end
      rescue Net::OpenTimeout
        raise Net::OpenTimeout, "Time is up!"
      end

      @logger.info "Connected to #{@options["host"]}:#{@options["port"]}"

      login

      command = ""
      while command != "-1"
        command = get_user_command
        response = waitfor_response command
        print response.chomp
      end
      @logger.info "Connection is closed !"
    end

    def waitfor_response(command)
      response = ""
      line = ""
      @socket.puts(command)
      until line.include?(@options["prompt"])
        unless @socket.wait_readable(2)
          @logger.info "Time is up!"
          exit
        end
        line = @socket.gets
        response += line
      end
      response
    end

    def login
      response = ""
      until response.include? "200"
        @logger.info "Enter valid credential for connection."
        print "Username: "
        username = get_user_command
        print "Password: "
        password = get_user_command

        response = waitfor_response "#{username},#{password}"
        if response.include?("403")
          @logger.info "Connection is closed !"
          exit
        end
      end

      @logger.info "SUCCESS !"
      @options["prompt"] = "#{username} ~]$ "
      print @options["prompt"]
    end

    def get_user_command
      STDIN.gets.chomp
    end

  end
end
