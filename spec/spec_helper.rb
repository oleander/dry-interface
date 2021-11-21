# frozen_string_literal: true

require "dry/interface"
require_relative "examples"
require_relative "support"

RSpec.configure do |config|
  config.include Support
  config.extend Support
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
