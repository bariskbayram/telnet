# frozen_string_literal: true

require_relative 'telnet/version'
require_relative  'telnet/server'
require_relative  'telnet/client'
require_relative 'telnet/argument_parser'

class TelnetServer
  class << self
    def start
      server = Server.new(options)
      server.serve
    end

    def options
      @@options = {
        host: '127.0.0.1',
        port: '4242',
        timeout: 5
      }
    end
  end
end

class TelnetClient
  class << self
    def start
      client = Client.new(options)
      client.start
    end

    def options
      @@options = {
        host: '127.0.0.1',
        port: '4242',
        timeout: 30,
        wait_time: 30,
        prompt: '~]$ '
      }
    end
  end
end
