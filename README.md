# Telnet

Simple Telnet Client-Server functionality with Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'telnet'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install telnet

## Usage

Server side:

    $ ruby start_server.rb

    $ ruby start_server.rb -h

    Options:
        -i HOST                          ip address (127.0.0.1)
        -p PORT                          port number (4242)
        -t TIMEOUT                       time to wait for executing command (5)


Client side:

    $ ruby start_client.rb               start client with default options

    $ ruby start_client.rb -h            help

    Options:
        -i HOST                          ip address (127.0.0.1)
        -p PORT                          port number (4242)
        -r SESSION_ID                    reattach to a detached session
        -l                               get list of active sessions
        -t TIMEOUT                       time to wait for connection (30)
        -w WAIT_TIME                     time to wait for response (30)



You can use ctrl-z to detach the connection from the session, use below options for attach to the session again:

        $ ruby start_client.rb -r 1          attach to the session that is specified with ID

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).