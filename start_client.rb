# frozen_string_literal: true

require "./lib/telnet/client"

options = {}

iterate = 0
if ARGV[0].include? "-r"
  options["resume"] = true
  options["resume_id"] = ARGV[1]
  iterate = 2
end

options["host"] = ARGV[iterate]
options["port"] = ARGV[iterate + 1]
options["timeout"] = Integer(ARGV[iterate + 2]) unless ARGV[iterate + 2].nil?
options["waittime"] = Integer(ARGV[iterate + 3]) unless ARGV[iterate + 3].nil?

client = Telnet::Client.new(options)
client.start
