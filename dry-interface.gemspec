# frozen_string_literal: true

require_relative "lib/dry/interface/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-interface"
  spec.version       = Dry::Interface::VERSION
  spec.authors       = ["Linus Oleander"]
  spec.email         = ["oleander@users.noreply.github.com"]
  spec.homepage      = "https://github.com/oleander/dry-interface"
  spec.summary       = "Dry::Interface"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb"]
  spec.add_dependency "activesupport"
  spec.add_dependency "dry-struct"
  spec.add_dependency "dry-types"

  spec.metadata = { "rubygems_mfa_required" => "true" }
end
