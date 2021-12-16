# frozen_string_literal: true

describe Dry::Interface::Abstract do
  describe "::to_s" do
    subject(:person) do
      Class.new(described_class) do
        attribute :name, String
        def self.name
          "Person"
        end
      end
    end

    it "returns the class with no sub types" do
      expect(person.to_s).to eql("Person<[]>")
    end

    context "when a unit type inherits" do
      let!(:developer) do
        Class.new(person::Unit) do
          def self.name
            "Developer"
          end
        end
      end

      it "returns the class with no sub types" do
        expect(developer.to_s).to eql("Developer")
        expect(person.to_s).to eql("Person<[Developer]>")
      end
    end

    context "when a concrete type inherits" do
      let!(:driver) do
        Class.new(person::Concrete) do
          def self.name
            "Driver"
          end
        end
      end

      it "returns the class with no sub types" do
        expect(driver.to_s).to eql("Driver")
        expect(person.to_s).to eql("Person<[Driver]>")
      end
    end

    context "when an abstract type inherits" do
      let!(:runner) do
        Class.new(person::Abstract) do
          def self.name
            "Runner"
          end
        end
      end

      it "returns the class with no sub types" do
        expect(runner.to_s).to eql("Runner<[]>")
        expect(person.to_s).to eql("Person<[Runner<[]>]>")
      end

      context "when abstract class gets inherited" do
        let!(:slow) do
          Class.new(runner::Unit) do
            def self.name
              "Slow"
            end
          end
        end

        it "returns the class with no sub types" do
          expect(slow.to_s).to eql("Slow")
          expect(person.to_s).to eql("Person<[Runner<[Slow]>]>")
        end
      end
    end
  end

  describe "::new" do
    subject(:result) { person.new(input) }

    let(:person) do
      Class.new(described_class) do
        attribute :name, String
      end
    end

    let(:input) { { name: "Jane" } }

    it "raises an error" do
      expect { subject }.to raise_error(NotImplementedError)
    end

    context "when a concrete type inherits" do
      let!(:developer) do
        Class.new(person::Concrete) do
          def self.name
            "Developer"
          end
        end
      end

      let(:input) { { name: "Jane" } }

      it { is_expected.to be_instance_of(developer) }
    end
  end

  describe "::call" do
    subject(:result) { person.call(input) }

    let(:person) do
      Class.new(described_class) do
        attribute :name, String
        def self.name
          "Person"
        end
      end
    end

    let(:input) { { name: "Jane" } }

    it "raises an error" do
      expect { subject }.to raise_error(NotImplementedError)
    end

    context "given a concrete subtype" do
      let(:person) do
        Class.new(described_class::Concrete) do
          attribute :name, String
        end
      end

      context "given a hash" do
        let(:input) { { name: "Jane" } }

        it "returns a person" do
          expect(result).to be_instance_of(person)
        end
      end

      context "given a string" do
        let(:input) { "Jane" }

        it "raises an error" do
          expect { result }.to raise_error(Dry::Interface::Error)
        end
      end

      context "given a person" do
        let(:input) { person.new(name: "Jane") }

        it "returns a person" do
          expect(result).to be_instance_of(person)
        end
      end
    end

    context "given a unit subtype" do
      let(:person) do
        Class.new(described_class::Unit) do
          attribute :name, String
          def self.name
            "Person"
          end
        end
      end

      context "given a string" do
        let(:input) { "Jane" }

        it "returns a person" do
          expect(result).to be_instance_of(person)
        end
      end

      context "given a hash" do
        let(:input) { { name: "Jane" } }

        it "returns a person" do
          expect(result).to be_instance_of(person)
        end
      end

      context "given a person" do
        let(:input) { person.new(name: "Jane") }

        it "returns a person" do
          expect(result).to be_instance_of(person)
        end
      end
    end

    context "given an abstract sub type" do
      let!(:developer) do
        Class.new(person::Abstract) do
          attribute :language, String
          def self.name
            "Developer"
          end
        end
      end

      context "given a hash" do
        let(:input) { { language: "Ruby", name: "John" } }

        it "raises an error" do
          expect { result }.to raise_error(NotImplementedError)
        end
      end

      context "when extended with a sub type" do
        let!(:ruby_developer) do
          Class.new(developer::Unit) do
            attribute :language, Types.Value("ruby")
            def self.name
              "RubyDeveloper"
            end
          end
        end

        context "given the correct value :ruby" do
          let(:input) { { language: "ruby", name: "John" } }

          it "returns a person" do
            expect(result).to be_instance_of(ruby_developer)
          end
        end

        context "given the incorrect value :java" do
          let(:input) { { language: "java", name: "John" } }

          it "raises an error" do
            expect { result }.to raise_error(Dry::Types::CoercionError)
          end
        end
      end
    end
  end
end
