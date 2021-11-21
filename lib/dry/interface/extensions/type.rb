# frozen_string_literal: true

require "dry/struct"
require "dry/types"

module Dry
  class Interface
    module Extensions
      module Type
        module Types
          include Dry::Types()
        end

        refine String do
          # Converts type references into types
          #
          # @example A strict string into a type
          #   type = "strict.string".to_type
          #
          #   type.valid?("string") # => true
          #   type.valid?(:symbol)  # => false
          #
          # @example A (strict) symbol into a type
          #   type = "symbol".to_type
          #
          #   type.valid?(:symbol)  # => true
          #   type.valid?("string") # => false
          #
          # @return [Dry::Types::Type]
          # @raise [ArgumentError] if the type is not a valid type
          def to_type
            Dry::Types[self]
          rescue Dry::Container::Error
            raise ArgumentError, "Type reference [#{inspect}] not found in Dry::Types"
          end
        end

        refine Object do
          def to_type
            raise ArgumentError, <<~ERROR
              Cannot convert [#{inspect}] (#{self.class}) into a type using [#{inspect}#to_type]
              Expected value of type Dry::Struct, Dry::Types or native Ruby module or class

              ProTip: Replace [#{inspect}] with [Value(#{inspect})] to allow for [#{inspect}]

              General examples:
              Dry::Types:
              Dry::Types["coercible.string"]
              "strict.string"
              "string"
              Fixed values:
              Value('undefined')
              Value(:id)
              Instance of class:
              Hash
              Array
              String
              [String]
              [String, Symbol]
              [[String, Symbol]]
              { Symbol => Hash }
              { Symbol => [Pathname] }
              Constructors:
              Struct.new(:value)
              OpenStruct
              Modules:
              Enumerable
              Comparable
            ERROR
          end
        end

        refine Dry::Types::Type do
          # Dry::Types::Type is already a type in itself
          # Used to streamline the API for all objects
          #
          # @example Dry type to dry type
          #   type = Dry::Types['string'].to_type
          #
          #   type.valid?("string") # => true
          #   type.valid?(:string)  # => false
          #
          # @return [Dry::Types::Type]
          alias_method :to_type, :itself
        end

        refine Module do
          # Ensures passed value includes module
          #
          # @example Check for enumerable values
          #   type = Enumerable.to_type
          #
          #   type.valid?([])  # => true
          #   type.valid?({})  # => true
          #   type.valid?(nil) # => false
          #
          # @return [Dry::Types::Constrained]
          def to_type
            Types::Any.constrained(type: self)
          end
        end

        refine Class do
          # Wrapps class in a type constructor using ::new as initializer
          #
          # @example With a custom class
          #   type = Struct.new(:value).to_type
          #
          #   type.valid?('value')            # => true
          #   type.valid?                     # => false
          #
          # @example With a native Ruby class
          #   type = String.to_type
          #
          #   type.valid?('value')            # => true
          #   type.valid?(:symbol)            # => false
          #
          # @example With an instance of the class
          #   Person = Struct.new(:name)
          #
          #   type = Person.to_type
          #
          #   type.valid?('value')             # => true
          #   type.valid?(Person.new('John'))  # => true
          #   type.valid?                      # => false
          #
          # @example With a class without constructor args
          #   type = Mutex.to_type
          #
          #   type.valid?                      # => true
          #   type.valid?('value')             # => false
          #
          # @return [Dry::Types::Constructor]
          def to_type
            Types.const_get(name).then do |maybe_type|
              maybe_type == self ? to_constructor : maybe_type
            end
          rescue NameError, TypeError
            to_constructor
          end

          private

          def to_constructor
            Types.Instance(self) | Types.Constructor(self, method(:new))
          end
        end

        refine Hash do
          # Recursively creates a hash type from {keys} & {values}
          #
          # @example With dynamic key and static value
          #   type = { String => 'value' }
          #
          #   type.valid?('string' => 'value') # => true
          #   type.valid?(symbol: 'value')     # => false
          #   type.valid?('string' => 'other') # => false
          #
          # @example With dynamic key and value
          #   type = { String => Enumerable }.to_type
          #
          #   type.valid?('string' => [])      # => true
          #   type.valid?(symbol: [])          # => false
          #   type.valid?('string' => :symbol) # => false
          #
          # @return [Dry::Types::Constrained, Dry::Types::Map]
          def to_type
            return Types::Hash if empty?

            map { |k, v| Types::Hash.map(k.to_type, v.to_type) }.reduce(:|)
          end
        end

        refine Array do
          # Recursively creates an array type from {self}
          #
          # @example With member type
          #   type = [String].to_type
          #
          #   type.valid?(['string'])            # => true
          #   type.valid?([:symbol])             # => false
          #
          # @example Without member type
          #   type = [].to_type
          #
          #   type.valid?(['anything'])          # => true
          #   type.valid?('not-an-array')        # => false
          #
          # @example With nested members
          #   type = [[String]].to_type
          #
          #   type.valid?([['string']])          # => true
          #   type.valid?([[:symbol]])           # => false
          #   type.valid?(['string'])            # => false
          #
          # @example With combined types
          #   type = [String, Symbol].to_type
          #
          #   type.valid?(['string', :symbol])   # => true
          #   type.valid?(['string'])            # => true
          #   type.valid?([:symbol])             # => true
          #   type.valid?([])                    # => true
          #   type.valid?(:symbol)               # => false
          #
          # @return [Dry::Types::Constrained]
          def to_type
            return Types::Array if empty?

            Types.Array(map(&:to_type).reduce(:|))
          end
        end
      end
    end
  end
end
