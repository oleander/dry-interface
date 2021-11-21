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
    autoload :Extensions, "dry/interface/extensions"
    autoload :Types, "dry/interface/types"

    extend ActiveSupport::DescendantsTracker
    extend ActiveSupport::Inflector

    using Extensions::Default
    using Extensions::Type

    schema schema.strict(true)

    delegate(*%i[
               Constructor
               Interface
               Instance
               Constant
               Nominal
               Value
               Array
               Hash
               Any
             ], to: Types)

    Types.constants.each do |constant|
      raise "#{const_get(constant)} is already defined"
    rescue NameError
      const_set(constant, Types.const_get(constant))
    end

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
      return super unless type

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

    # Adds attribute {name} to the struct
    #
    # @example Add a new attribute
    #   class User < Dry::Struct
    #     attribute :name, String
    #   end
    #
    # @example Add a new attribute with a default value
    #   class User < Dry::Struct
    #     attribute :name, String, default: "John"
    #   end
    #
    # @example Add a new attribute with constraints
    #   class User < Dry::Struct
    #     attribute :name, String, size: 3..20
    #   end
    #
    # @example Add a new attribute with array type
    #   class User < Dry::Struct
    #     attribute :name, [String]
    #   end
    #
    # @param name [Symbol]
    # @param constrains [Array<#to_type>]
    # @option default [#call, Any]
    # @return [void]
    def self.attribute(field, *constrains, **options, &block)
      alias_fields(field, **options) do |inner_options|
        super(field, build_type_from(*constrains, **inner_options), &block)
      end
    end

    # Optional version of {#attribute}
    #
    # @see #attribute
    def self.attribute?(field, *constrains, **options, &block)
      alias_fields(field, **options) do |inner_options|
        super(field, build_type_from(*constrains, **inner_options), &block)
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

    def self.alias_fields(_field, aliases: [], **options, &block)
      if options.key?(:alias)
        aliases << options.delete(:alias)
      end

      block[options]

      aliases.each do |alias_name|
        alias_method alias_name, name
      end
    end

    # @api private
    def self.build_type_from(*constrains, **options)
      unless (type = constrains.map(&:to_type).reduce(:|))
        return build_type_from(Dry::Types["any"], **options)
      end

      if options.key?(:default)
        options.delete(:default).to_default.then do |default_proc|
          return build_type_from(type.default(&default_proc), **options)
        end
      end

      if options.empty?
        return type
      end

      build_type_from(type.constrained(**options))
    end
  end
end
