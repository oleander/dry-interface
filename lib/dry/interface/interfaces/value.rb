# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      module Value
        extend ActiveSupport::Concern
        include Concrete

        included do |child|
          otherwise do |value, type, &error|
            names = child.type.attribute_names

            unless names.one?
              raise ArgumentError, "Value classes must have exactly one attribute, got [#{names.join(', ')}] (#{names.count}) for [#{child}]"
            end

            type[names.first => value, &error]
          end
        end
      end
    end
  end
end
