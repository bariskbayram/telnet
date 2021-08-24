# frozen_string_literal: true

require 'optparse'

module TelnetServerClient
  class ArgumentParser
    def self.client_parse
      client_options = {
        host: '127.0.0.1',
        port: '4242',
        timeout: 30,
        wait_time: 30,
        prompt: '~]$ '
      }
      OptionParser.new do |opts|
        opts.banner = 'Usage: ruby start_client.rb [options]'

        opts.on('-i HOST', 'ip address (127.0.0.1)') do |host|
          client_options[:host] = host
        end
        opts.on('-p PORT', 'port number (4242)') do |port|
          client_options[:port] = port
        end
        opts.on('-r SESSION_ID', 'reattach to a detached session') do |attach_session_id|
          client_options[:attach_session_id] = attach_session_id
        end
        opts.on('-l', 'get list of active sessions') do
          client_options[:active_sessions] = true
        end
        opts.on('-t TIMEOUT', Integer, 'time to wait for connection (30)') do |timeout|
          client_options[:timeout] = timeout
        end
        opts.on('-w WAIT_TIME', Integer, 'time to wait for response (30)') do |wait_time|
          client_options[:wait_time] = wait_time
        end
      end.parse!
      client_options
    end

    def self.server_parse
      server_options = {
        host: '127.0.0.1',
        port: '4242',
        timeout: 5
      }
      OptionParser.new do |opts|
        opts.banner = 'Usage: ruby start_server.rb [options]'

        opts.on('-i HOST', 'ip address (127.0.0.1)') do |host|
          server_options[:host] = host
        end
        opts.on('-p PORT', 'port number (4242)') do |port|
          server_options[:port] = port
        end
        opts.on('-t TIMEOUT', Integer, 'time to wait for executing command (5)') do |timeout|
          server_options[:timeout] = timeout
        end
      end.parse!
      server_options
    end
  end
end
