# frozen_string_literal: true

describe Dry::Interface::Concrete do
  describe "::to_s" do
    let(:person) do
      Class.new(described_class) do
        attribute :name, String
        def self.name
          "Person"
        end
      end
    end

    it "returns the class name" do
      expect(person.to_s).to eql("Person")
    end
  end

  describe "::new" do
    subject { person.new(input) }

    let(:person) do
      Class.new(described_class) do
        attribute :name, String
      end
    end

    context "when passed a string" do
      let(:input) { "John" }

      it "raises an error" do
        expect { subject }.to raise_error(Dry::Struct::Error)
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

      it "raises an error" do
        expect { subject }.to raise_error(Dry::Struct::Error)
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
