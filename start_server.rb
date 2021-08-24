# frozen_string_literal: true

require './lib/telnet/server'
require './lib/telnet/argument_parser'

options = TelnetServerClient::ArgumentParser.server_parse

server = TelnetServerClient::Server.new(options)
server.serve
