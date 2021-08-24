# frozen_string_literal: true

require './lib/telnet/client'
require './lib/telnet/argument_parser'

options = TelnetServerClient::ArgumentParser.client_parse

client = TelnetServerClient::Client.new(options)
client.start
