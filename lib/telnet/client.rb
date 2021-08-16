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
      @options["prompt"] = "~]$ "

      trap("INT", proc { close_client })
      trap("TSTP", proc { send_suspend_command })
      trap("SIGCONT", proc { send_resume_command })

    end

    def start
      begin
        Timeout.timeout(Integer(@options["timeout"]), Net::OpenTimeout) do
          @socket = TCPSocket.open(@options["host"], @options["port"])
        end
      rescue Net::OpenTimeout
        raise Net::OpenTimeout, "Time is up!"
      end

      check_alive_req = "OK"
      unless @options["resume"].nil?
        check_alive_req = "#{@options["resume_id"]},SRESUME"
      end

      response = send_command(check_alive_req)

      if response.include?("SESSION_CREATE")
        login
      elsif response.include?("SESSION_RESUME")
        print waitfor_response.chomp
      end

      loop do
        command = get_user_command
        response = send_command(command)
        print response.chomp
      end
      @logger.info("Connection is closed !")
    end

    def send_command(command)
      @socket.puts(command)
      waitfor_response
    end

    def waitfor_response
      response = ""
      line = ""
      until line.include?(@options["prompt"])
        unless @socket.wait_readable(@options["waittime"])
          @logger.info("Time is up!")
          exit
        end
        line = @socket.gets
        response += line
      end
      response
    end

    def login
      response = ""
      until response.include?("200")
        @logger.info("Enter valid credential for connection.")
        print "Username: "
        username = get_user_command
        print "Password: "
        password = get_user_command

        response = send_command("#{username},#{password}")
        if response.include?("403")
          @logger.info("Connection is closed !")
          exit
        end
      end

      @logger.info("SUCCESS !")
      @options["prompt"] = "#{username} ~]$ "
      print @options["prompt"]
    end

    def get_user_command
      STDIN.gets.chomp
    end

    def send_suspend_command
      @socket.puts("SSTOP")
      puts("\nSuspending...")
      `kill -STOP #{$$}`
    end

    def send_resume_command
      @socket.puts("SRESUME")
      puts("\nResuming...")
    end

    def close_client
      @socket.puts("SKILL")
      puts("\nTerminating...")
      exit
    end

  end
end
