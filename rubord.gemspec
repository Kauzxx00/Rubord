# frozen_string_literal: true

require_relative "lib/rubord"

Gem::Specification.new do |spec|
  spec.name          = "rubord"
  spec.version       = Rubord::VERSION
  spec.authors       = ["Kauã Eduardo"]
  spec.email         = ["kaua.eduardo.dev@email.com"]

  spec.summary       = "Discord API wrapper"
  spec.description   = "Rubord is a modern library for building Discord bots in Ruby, with support for Gateway, REST, Interactions, and Components v2."
  spec.homepage      = "https://github.com/kauzxx00/rubord"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir.glob(%w[
    lib/**/* 
    README.md 
    LICENSE
  ])

  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", ">= 2.0.0"
  spec.add_dependency "websocket-client-simple", ">= 0.9.0"
end
