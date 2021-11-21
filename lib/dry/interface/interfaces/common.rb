# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      module Common
        extend ActiveSupport::Concern

        class_methods do
          def name
            demodulize(super)
          end
        end
      end
    end
  end
end
