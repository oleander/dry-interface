# frozen_string_literal: true

module Dry
  class Concrete
    class Value < self
      def self.new(value, *other, &block)
        case value
        in Hash => attributes then super(attributes, *other, &block)
        in Dry::Struct => instance then instance
        else
          case attribute_names
          in [] then raise ArgumentError, "[#{self}] has no attributes, one is required"
          in [key] then super({ key => value }, *other, &block)
          else
            raise ArgumentError,
                  "[#{self}] has more than one attribute: #{attribute_names.join(', ')}"
          end
        end
      end
    end
  end
end
