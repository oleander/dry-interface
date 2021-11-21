# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      module Concrete
        extend ActiveSupport::Concern
        include Common

        included do
          class << self
            alias_method :new, :_new
          end
        end

        class_methods do
          def type
            direct_descendants.first or self
          end

          def named
            direct_descendants.first&.name or name
          end
        end
      end
    end
  end
end
