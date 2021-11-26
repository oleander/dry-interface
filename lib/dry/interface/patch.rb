# frozen_string_literal: true

module Dry
  class Interface
    module Patch
      autoload :Value, "dry/interface/patch/value"
      autoload :Abstract, "dry/interface/patch/abstract"
      autoload :Concrete, "dry/interface/patch/concrete"
    end
  end
end
