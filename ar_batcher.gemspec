# frozen_string_literal: true

require_relative "lib/ar_batcher/version"

Gem::Specification.new do |spec|
  spec.name = "ar_batcher"
  spec.version = ArBatcher::VERSION
  spec.authors = ["Baptiste Jublot"]
  spec.email = ["baptiste@demarque.com"]

  spec.summary = "Lazy and easy batch loader for ActiveRecord"
  spec.description = "Lazy and easy batch loader for ActiveRecord"
  spec.homepage = "https://github.com/baptistejub/ar_batcher"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/baptistejub/ar_batcher"
  spec.metadata["changelog_uri"] = "https://github.com/baptistejub/ar_batcher/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "Rakefile", "README.md"]
end
