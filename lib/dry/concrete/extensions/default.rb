# frozen_string_literal: true

module Dry
  class Concrete
    module Extensions
      module Default
        refine Proc do
          # @example A string type with a proc default value
          #  Dry::Types['string'].default { 'default' }
          #
          # @return [#call(Dry::Types::Type)]
          def to_default
            -> type { type[call] }.freeze
          end
        end

        refine Object do
          # @example String type with default value
          #   Dry::Types['string'].default('foo')
          #
          # @return [#call(Dry::Types::Type)]
          def to_default
            -> type = Dry::Types["any"] { type[self] }.to_default
          end
        end
      end
    end
  end
end
