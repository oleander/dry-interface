module Dry
  autoload :Concrete, "dry/concrete"

  class Interface < Concrete
    autoload :Interfaces, "dry/interface/interfaces"

    include ActiveSupport::Configurable

    config.order = Hash.new(-1)

    class << self
      alias _new new
      alias _call call
      alias _call_safe call_safe
      alias _call_unsafe call_unsafe

      delegate :call, to: :subtype
      delegate :call_safe, to: :subtype
      delegate :call_unsafe, to: :subtype
    end

    # Allow types structs to be ordered
    #
    # @param names [Array<Symbol>]
    def self.order(*names)
      result = names.each_with_index.reduce(EMPTY_HASH) do |acc, (name, index)|
        acc.merge(name.to_s => index)
      end

      config.order = result
    end

    # @return [String]
    def self.to_s
      format("%<name>s<[%<types>s]>", name: name, types: subtypes.map(&:to_s).join(" | "))
    end

    def self.reduce(input, subtype)
      case input
      in { result: }
        input
      in { value: }
        { result: subtype.call(value) }
      end
    rescue Dry::Struct::Error => e
      em = Dry::Types::ConstraintError.new(e.message, input.fetch(:value))
      input.merge(errors: input.fetch(:errors, []) + [em])
    rescue Dry::Types::CoercionError => e
      input.merge(errors: input.fetch(:errors, []) + [e])
    end

    # Internal type represented by {self}
    #
    # @return [Dry::Struct::Sum, Dry::Struct::Class]
    def self.subtype
      Constructor(self) do |value, _type, &error|
        error ||= lambda do |error|
          raise error
        end

        if subtypes.empty?
          raise NotImplementedError, "No subtypes defined for #{name}"
        end

        output = subtypes.reduce({ value: value }, &method(:reduce))

        case output
        in { result: }
          result
        in { errors: }
          error[Dry::Types::MultipleError.new(errors)]
        in Dry::Struct
          output
        end
      end
    end

    # Internal types represented by {self}
    #
    # @return [Dry::Struct::Class]
    def self.subtypes
      types = subclasses.flat_map(&:subclasses)

      return types if config.order.empty?

      types.sort_by do |type|
        config.order.fetch(demodulize(type.name))
      end
    end

    # @param name [Symbol]
    #
    # @return [Abstract::Class]
    def self.const_missing(name)
      case name
      in :Concrete
        Class.new(self) do
          prepend Interfaces::Concrete
        end
      in :Abstract
        Class.new(self) do
          prepend Interfaces::Abstract
        end
      in :Unit
        Class.new(self) do
          prepend Interfaces::Unit
        end
      else
        super
      end
    end
  end
end
