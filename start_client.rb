# frozen_string_literal: true

require './lib/telnet/client'
require './lib/telnet/argument_parser'

options = ArgumentParser.client_parse

client = Client.new(options)
client.start
