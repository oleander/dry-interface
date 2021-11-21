# frozen_string_literal: true

using(Module.new do
  refine Class do
    alias_method :to_class, :itself
  end

  refine Module do
    alias_method :to_class, :itself
  end

  refine Object do
    alias_method :to_class, :class
  end
end)

# Used by below examples
module Types
  include Dry::Types()
end

RSpec.shared_examples "a dry type" do
  it "is part of dry types" do
    expect(Types.const_get(described_class.name)).not_to eq(described_class)
  end
end

RSpec.shared_examples "a ruby type" do
  it "is not part of dry types" do
    expect(Types.const_get(described_class.name)).to eq(described_class)
  end
end

RSpec.shared_examples "a type" do |owner = described_class.to_class|
  subject { type }

  describe "#call" do
    context "with valid input" do
      it "returns the correct type" do
        expect(type.call(valid)).to be_a(owner)
      end

      context "when chained" do
        subject(:chained) { type >> type }

        it "returns the correct type" do
          expect(chained.call(valid)).to be_a(owner)
        end
      end
    end
  end

  describe "#valid?" do
    context "with valid input" do
      it { is_expected.to be_valid(valid) }

      context "when chained" do
        subject { type >> type }

        it { is_expected.to be_valid(valid) }
      end
    end

    context "with invalid input" do
      it { is_expected.not_to be_valid(invalid) }

      context "when chained" do
        subject { type >> type }

        it { is_expected.not_to be_valid(invalid) }
      end
    end
  end
end

RSpec.shared_examples "a type without args" do |owner = described_class.to_class|
  subject { type }

  describe "#call" do
    it "returns the correct type" do
      expect(type.call).to be_a(owner)
    end

    context "when chained" do
      subject(:chained) { type >> type }

      it "returns the correct type" do
        expect(chained.call).to be_a(owner)
      end
    end
  end

  describe "#valid?" do
    it { is_expected.to be_valid }

    context "when chained" do
      subject { type >> type }

      it { is_expected.to be_valid }
    end
  end
end

RSpec.shared_examples "a struct" do
  subject(:result) { struct.new(input) }

  let(:input) { valid }

  context "when input is valid" do
    let(:input) { valid }

    it { is_expected.to have_attributes(valid) }
  end

  context "when input is invalid" do
    let(:input) { invalid }

    it "raises an error" do
      expect { subject }.to raise_error(struct::Error)
    end
  end
end
