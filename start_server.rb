require './lib/telnet/server'

s = Telnet::Server.new("127.0.0.1", "4242")
s.serve