# frozen_string_literal: true

require "bundler/setup"

Bundler.require

require "dry/interface"

class Hello < Dry::Interface
end
