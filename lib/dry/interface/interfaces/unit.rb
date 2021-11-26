# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      module Unit
        extend ActiveSupport::Concern

        prepended do
          class << self
            alias_method :call, :_call
            alias_method :call_unsafe, :_call_unsafe
            alias_method :call_safe, :_call_safe
          end
        end

        class_methods do
          # Class name without parent module
          #
          # @return [String]
          def to_s
            demodulize(name)
          end

          # Allows a struct to be called without a hash
          #
          # @param value [Dry::Struct, Hash, Any]
          # @param block [Proc]
          #
          # @return [Dry::Struct]

          def new(value, *other, &block)
            case value
            in Hash => attributes then _new(attributes, *other, &block)
            in Dry::Struct => instance then instance
            else
              case attribute_names
              in [] then raise ArgumentError, "[#{self}] has no attributes, one is required"
              in [key] then _new({ key => value }, *other, &block)
              else
                raise ArgumentError, "[#{self}] has more than one attribute: #{attribute_names.join(', ')}"
              end
            end
          end
        end
      end
    end
  end
end
