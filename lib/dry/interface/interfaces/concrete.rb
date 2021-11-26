# frozen_string_literal: true

# module C
#   def structs
#     [self]
#   end

#   def named
#     to_s
#   end

#   def type
#     self
#   end
# end

module Dry
  class Interface
    module Interfaces
      module Concrete
        extend ActiveSupport::Concern

        prepended do
          class << self
            alias_method :call_safe, :_call_safe
            alias_method :call_unsafe, :_call_unsafe
            alias_method :new, :_new
            alias_method :call, :_call
          end
        end
        # included do
        #   class << self
        #     alias_method :call, :_call
        #   end
        # end

        class_methods do
          # Class name without parent module
          #
          # @return [String]
          def to_s
            demodulize(name)
          end
        end
      end
    end
  end
end
