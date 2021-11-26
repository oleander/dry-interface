# frozen_string_literal: true

describe Dry::Concrete::Value do
  describe "::new" do
    subject { person.new(input) }

    let(:person) do
      Class.new(described_class) do
        attribute :name, String
      end
    end

    context "when passed a string" do
      let(:input) { "John" }

      it "returns a new instance of the class" do
        expect(subject).to be_a(person)
      end

      it "sets the attributes" do
        expect(subject.name).to eql("John")
      end
    end

    context "when passed a hash" do
      let(:input) { { name: "John" } }

      it "returns a new instance of the class" do
        expect(subject).to be_a(person)
      end

      it "sets the attributes" do
        expect(subject.name).to eql("John")
      end
    end

    context "when passed a struct" do
      let(:input) { person.new({ name: "John" }) }

      it "returns a new instance of the class" do
        expect(subject).to eq(input)
      end

      it "sets the attributes" do
        expect(subject.name).to eql("John")
      end
    end
  end

  describe "::call" do
    subject { person.call(input) }

    let(:person) do
      Class.new(described_class) do
        attribute :name, String
      end
    end

    context "when passed a string" do
      let(:input) { "John" }

      it "returns a new instance of the class" do
        expect(subject).to be_a(person)
      end

      it "sets the attributes" do
        expect(subject.name).to eql("John")
      end
    end

    context "when passed a hash" do
      let(:input) { { name: "John" } }

      it "returns a new instance of the class" do
        expect(subject).to be_a(person)
      end

      it "sets the attributes" do
        expect(subject.name).to eql("John")
      end
    end

    context "when passed a struct" do
      let(:input) { person.call({ name: "John" }) }

      it "returns a new instance of the class" do
        expect(subject).to eq(input)
      end

      it "sets the attributes" do
        expect(subject.name).to eql("John")
      end
    end
  end
end
