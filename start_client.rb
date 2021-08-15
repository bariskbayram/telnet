require './lib/telnet/client'

options = Hash.new

options["host"] = ARGV[0]
options["port"] = ARGV[1]
options["timeout"] = Integer(ARGV[2]) unless ARGV[2].nil?
options["waittime"] = Integer(ARGV[3]) unless ARGV[3].nil?

client = Telnet::Client.new(options)
client.start