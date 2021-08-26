# frozen_string_literal: true

require './lib/telnet/server'
require './lib/telnet/argument_parser'

options = ArgumentParser.server_parse

server = Server.new(options)
server.serve
