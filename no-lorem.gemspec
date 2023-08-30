# frozen_string_literal: true

require_relative "lib/no_lorem/version"

Gem::Specification.new do |s|
  s.name        = "no-lorem"
  s.version     = NoLorem::Version::STRING
  s.summary     = "Find unwanted elements in your source code"
  s.description = <<-DESCRIPTION
    No-lorem is is a tool that can search through ruby code for undesired words in strings or constants
    identifying undesired libraries.
  DESCRIPTION
  s.authors     = ["Alain Pannetrat"]
  s.email       = "apannetrat@cloudsecurityalliance.org"
  s.files       = Dir.glob("lib/**/*.rb")
  s.bindir      = "bin"
  s.executables = ["no-lorem"]
  s.extra_rdoc_files = ["README.md", "MIT-LICENSE"]
  s.homepage    = "https://example.com"
  s.license     = "MIT"

  s.required_ruby_version = ">= 2.7.2"

  s.add_runtime_dependency("yaml", "~> 0.2")
  s.add_runtime_dependency("parser", "~> 3.2")
  s.add_runtime_dependency("pastel", "~> 0.8")
  s.add_runtime_dependency("warning", "~> 1.3")

  s.add_development_dependency("rspec", "~> 3.0")
  s.add_development_dependency("byebug", "~> 11.0")
  s.add_development_dependency("rubocop", "~> 1.0")
  s.add_development_dependency("rubocop-shopify", "~> 1.0")
  s.add_development_dependency("rubocop-rspec", "~> 2.0")
end
