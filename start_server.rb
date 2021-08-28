# frozen_string_literal: true

require './lib/telnet_server_client/server'
require './lib/telnet_server_client/argument_parser'

options = ArgumentParser.server_parse

server = Server.new(options)
server.serve
