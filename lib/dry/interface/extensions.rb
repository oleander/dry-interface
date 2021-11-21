# frozen_string_literal: true

module Dry
  class Interface
    module Extensions
      autoload :Default, "dry/interface/extensions/default"
      autoload :Type, "dry/interface/extensions/type"
    end
  end
end
