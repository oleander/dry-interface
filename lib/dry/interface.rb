# frozen_string_literal: true

require "active_support/core_ext/module/concerning"
require "active_support/core_ext/module/delegation"
require "active_support/descendants_tracker"
require "active_support/configurable"
require "active_support/inflector"
require "active_support/concern"
require "dry/struct"
require "dry/types"

module Dry
  class Interface < Dry::Struct
    autoload :Interfaces, "dry/interface/interfaces"
    autoload :VERSION, "dry/interface/version"

    extend ActiveSupport::DescendantsTracker
    extend ActiveSupport::Inflector

    schema schema.strict(true)

    concerning :New, prepend: true do
      prepended do
        class << self
          alias_method :_new, :new
        end
      end
    end

    module Types
      include Dry.Types()
    end

    def self.Value(...)
      Types.Value(...)
    end

    def self.type
      direct_descendants.map(&:type).reduce(&:|)
    end

    def self.named
      format "%<name>s<[%<names>s]>", { name: name, names: direct_descendants.map(&:named).join(" | ") }
    end

    def self.new(...)
      type.call(...)
    end

    def self.initializer(owner, &block)
      owner.schema owner.schema.constructor(&block)
    end

    def self.otherwise(&block)
      initializer(self) do |input, type, &error|
        type[input] { block[input, type, &error] }
      end
    end

    def self.const_missing(name)
      case name
      when :Abstract
        return Class.new(self) do
          include Interfaces::Abstract
        end
      when :Concrete
        return Class.new(self) do
          include Interfaces::Concrete
        end
      when :Value
        return Class.new(self) do
          include Interfaces::Value
        end
      end

      super
    end
  end
end
