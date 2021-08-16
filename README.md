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

    $ruby start_server.rb

Client side:

    $ruby start_client  <host>  <port> <timeout> <waittime>
    $ruby start_client 127.0.0.1 4242
    $ruby start_client 127.0.0.1 4242 10 10
    $ruby start_client  <host>  <port>

You can use ctrl+z for suspending the session, use below options for connecting to the session again:

    $ruby start_client -r <id> <host> <port>
    $ruby start_client -r 7 127.0.0.1 4242

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).