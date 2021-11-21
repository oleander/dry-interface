# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      module Abstract
        extend ActiveSupport::Concern
        include Common

        class_methods do
          def type
            direct_descendants.map(&:type).reduce(&:|) or raise "No types defined for [#{self}]"
          end

          def named
            format "%<name>s<[%<names>s]>", { name: name, names: direct_descendants.map(&:named).join(" | ") }
          end
        end
      end
    end
  end
end
