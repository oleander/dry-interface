# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      autoload :Value, "dry/interface/interfaces/value"
      autoload :Common, "dry/interface/interfaces/common"
      autoload :Abstract, "dry/interface/interfaces/abstract"
      autoload :Concrete, "dry/interface/interfaces/concrete"
    end
  end
end
