# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'net/protocol'
require 'logger'

module Telnet
  class Client
    def initialize(options)
      @options = options
      @logger = Logger.new($stdout)

      trap('INT', proc { close_session })
      trap('TSTP', proc { send_detach_session })
    end

    def start
      connect_to_server

      if @options[:active_sessions] == true
        response = send_command('SESSION_LIST')
        puts response.chomp.split(',')[0]
        exit
      end

      response = check_session_status
      print @options[:prompt] unless response.include?('SESSION_CREATE')
      login if response.include?('SESSION_CREATE')

      waitfor_broadcast_messages
      loop do
        command = user_command
        @socket.puts(command)
      end
      @logger.info('Connection is closed !')
    end

    def connect_to_server
      Timeout.timeout(@options[:timeout], Net::OpenTimeout) do
        @socket = TCPSocket.open(@options[:host], @options[:port])
      end
    rescue Net::OpenTimeout
      raise Net::OpenTimeout, 'Time is up!'
    end

    def check_session_status
      check_alive_req = 'OK'
      check_alive_req = "#{@options[:attach_session_id]},SESSION_ATTACH" unless @options[:attach_session_id].nil?
      send_command(check_alive_req)
    end

    def send_command(command)
      @socket.puts(command)
      waitfor_response
    end

    def waitfor_response
      response = ''
      line = ''
      until line.include?(@options[:prompt])
        unless @socket.wait_readable(@options[:wait_time])
          @logger.info('Time is up!')
          exit
        end
        line = @socket.gets
        response += line
      end
      response
    end

    def waitfor_broadcast_messages
      Thread.new do
        loop do
          line = ''
          until line.include?(@options[:prompt])
            line = @socket.gets
            if line.include?(@options[:prompt])
              print line.chomp unless line.include?('CLOSE_X')
            else
              print line
            end
          end
          exit if line.include?('CLOSE_X')
        end
      end
    end

    def login
      response = ''
      until response.include?('200')
        @logger.info('Enter valid credential for connection.')
        print 'Username: '
        username = user_command
        print 'Password: '
        password = user_command

        response = send_command("#{username},#{password}")
        if response.include?('403')
          @logger.info('Connection is closed !')
          exit
        end
      end

      @logger.info('SUCCESS !')
      print @options[:prompt] = "#{username} ~]$ "
    end

    def user_command
      $stdin.gets.chomp
    end

    def send_detach_session
      @socket.puts('SSTOP')
      puts("\nSession is detached.")
      exit
    end

    def close_session
      @socket.puts('SKILL')
      puts("\nSession is terminated.")
      exit
    end
  end
end
