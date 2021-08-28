# frozen_string_literal: true

require './lib/telnet_server_client/client'
require './lib/telnet_server_client/argument_parser'

options = ArgumentParser.client_parse

client = Client.new(options)
client.start
