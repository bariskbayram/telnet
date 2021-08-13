require './lib/telnet/client'

client = Telnet::Client.new(ARGV)
client.start