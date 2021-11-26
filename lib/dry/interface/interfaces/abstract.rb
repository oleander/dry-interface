# frozen_string_literal: true

require "active_support/core_ext/module/introspection"
require "active_support/core_ext/module/attribute_accessors"

module Dry
  class Interface
    module Interfaces
      module Abstract
        extend ActiveSupport::Concern

        class_methods do
          # Class name without parent module
          #
          # @return [String]
          def name
            demodulize(super)
          end

          def new(input, safe = false, &block)
            if safe
              call_safe(input, &block)
            else
              call_unsafe(input)
            end
          end
        end
      end
    end
  end
end
