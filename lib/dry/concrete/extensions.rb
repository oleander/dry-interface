# frozen_string_literal: true

module Dry
  class Concrete
    module Extensions
      autoload :Default, "dry/concrete/extensions/default"
      autoload :Type, "dry/concrete/extensions/type"
    end
  end
end
