# frozen_string_literal: true

require './lib/telnet/server'
require './lib/telnet/argument_parser'

options = Telnet::ArgumentParser.server_parse

server = Telnet::Server.new(options)
server.serve
