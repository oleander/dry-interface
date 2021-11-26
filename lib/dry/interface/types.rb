# frozen_string_literal: true

module Dry
  class Interface
    module Types
      include Dry.Types(:strict, :nominal, :coercible)
    end
  end
end
