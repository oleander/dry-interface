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
  autoload :Interface, "dry/interface"

  class Concrete < Dry::Struct
    autoload :Extensions, "dry/concrete/extensions"
    autoload :Value, "dry/concrete/value"
    autoload :Types, "dry/interface/types"

    schema schema.strict(true)

    include Dry.Types(:strict, :nominal, :coercible)

    extend ActiveSupport::DescendantsTracker
    include ActiveSupport::Configurable
    extend ActiveSupport::Inflector

    using Extensions::Default
    using Extensions::Type

    config.order = Hash.new(-1)

    delegate(
      :Constructor, :Interface, :Instance, :Constant,
      :Nominal, :Value, :Array, :Hash, :Any, to: :Types
    )

    def self.initializer(owner, &block)
      owner.schema owner.schema.constructor(&block)
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
        super(field, *build_type_from(*constrains, **inner_options, &block))
      end
    end

    # Optional version of {#attribute}
    #
    # @see #attribute
    def self.attribute?(field, *constrains, **options, &block)
      alias_fields(field, **options) do |inner_options|
        super(field, *build_type_from(*constrains, **inner_options, &block))
      end
    end

    def self.alias_fields(field, aliases: [], **options, &block)
      if options.key?(:alias)
        aliases << options.delete(:alias)
      end

      block[options]

      aliases.each do |alias_name|
        alias_method alias_name, field
      end
    end

    # @api private
    def self.build_type_from(*constrains, **options, &block)
      if block_given?
        return [Class.new(Concrete, &block)]
      end

      unless (type = constrains.map(&:to_type).reduce(:|))
        return EMPTY_ARRAY
      end

      if options.key?(:default)
        options.delete(:default).to_default.then do |default_proc|
          return build_type_from(type.default(&default_proc), **options)
        end
      end

      if options.empty?
        return [type]
      end

      build_type_from(type.constrained(**options))
    end
  end
end
