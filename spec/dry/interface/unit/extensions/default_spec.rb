# frozen_string_literal: true

RSpec.shared_examples "a failed default value" do |value|
  using described_class

  subject(:result) { value.to_default.call(type) }

  it "raises an error" do
    expect { result }.to raise_error(Dry::Types::ConstraintError)
  end
end

RSpec.shared_examples "an okay default value" do |value|
  using described_class

  subject { value.to_default.call(type) }

  it { is_expected.to eq(result) }
end

describe Dry::Interface::Extensions::Default do
  using described_class

  describe "#to_default" do
    let(:type) { Types::String }

    context "when not callable" do
      context "when of correct type" do
        it_behaves_like "an okay default value", "string" do
          let(:result) { "string" }
        end
      end

      context "when of incorrect type" do
        it_behaves_like "a failed default value", :symbol
      end
    end

    context "when proc" do
      context "when of correct type" do
        it_behaves_like("an okay default value", proc { "string" }) do
          let(:result) { "string" }
        end
      end

      context "when of incorrect type" do
        it_behaves_like("a failed default value", proc { :symbol })
      end
    end

    context "when lambda" do
      context "when of correct type" do
        it_behaves_like "an okay default value", -> { "string" } do
          let(:result) { "string" }
        end
      end

      context "when of incorrect type" do
        it_behaves_like "a failed default value", -> { :symbol }
      end
    end
  end
end
