# frozen_string_literal: true

require_relative 'telnet_server_client/version'
require_relative 'telnet_server_client/server'
require_relative 'telnet_server_client/server_base'
require_relative 'telnet_server_client/client'
require_relative 'telnet_server_client/session'
require_relative 'telnet_server_client/connection'

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
