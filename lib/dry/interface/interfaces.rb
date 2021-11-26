# frozen_string_literal: true

module Dry
  class Interface
    module Interfaces
      autoload :Unit, "dry/interface/interfaces/unit"
      autoload :Abstract, "dry/interface/interfaces/abstract"
      autoload :Concrete, "dry/interface/interfaces/concrete"
    end
  end
end
