# frozen_string_literal: true

require_relative 'lib/telnet/version'

Gem::Specification.new do |spec|
  spec.name          = "telnet-server-client"
  spec.version       = Telnet::VERSION
  spec.authors       = ["bariskbayram"]
  spec.email         = ["bariskaanb@gmail.com"]

  spec.summary       = "Simple telnet client and server functionality project"
  spec.description   = "Simple telnet client and server functionality project"
  spec.homepage      = "https://github.com/bariskbayram/telnet"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.4"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.7"
  spec.add_development_dependency "rubocop-performance"
end
