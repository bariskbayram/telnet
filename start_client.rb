# frozen_string_literal: true

require './lib/telnet/client'
require './lib/telnet/argument_parser'

options = Telnet::ArgumentParser.client_parse

client = Telnet::Client.new(options)
client.start
