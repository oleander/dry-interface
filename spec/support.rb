# frozen_string_literal: true

module Support
  module Types
    include Dry.Types()
  end

  def Value(...)
    Types.Value(...)
  end

  def define_struct(&block)
    Class.new(described_class::Concrete, &block)
  end

  def attribute(...)
    define_struct { attribute(...) }
  end
end
