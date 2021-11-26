# frozen_string_literal: true

require "dry/core/class_builder"

def build(name, **options, &block)
  Dry::Core::ClassBuilder.new(name: name, **options).call do |klass|
    if block_given?
      klass.class_eval(&block)
    end
  end
end

describe Dry::Interface do
  context "when keys are already defined" do
    class Owner < described_class::Concrete
    end

    class Animal < described_class::Concrete
      attribute :owner, Owner
    end

    subject { Animal.call(owner: owner) }

    let(:owner) { Owner.call({}) }

    it { is_expected.to be_a(Animal) }
  end

  context "when aliased using alias:" do
    subject { struct.call(name: "John") }

    let(:struct) { attribute :name, String, alias: :first_name }

    it { is_expected.to have_attributes(first_name: "John", name: "John") }
  end

  context "when aliased using aliases:" do
    subject { struct.call(name: "John") }

    let(:struct) { attribute :name, String, aliases: [:first_name] }

    it { is_expected.to have_attributes(first_name: "John", name: "John") }
  end

  context "when aliased using aliases: & alias:" do
    subject { struct.call(name: "John") }

    let(:struct) { attribute :name, String, aliases: [:first_name], alias: :nickname }

    it { is_expected.to have_attributes(first_name: "John", name: "John", nickname: "John") }
  end

  describe "::order" do
    let!(:a) { build("A", parent: parent::Unit) }
    let!(:b) { build("B", parent: parent::Concrete) }
    let!(:c) { build("C", parent: parent::Abstract) }

    context "when ordered in one direction" do
      subject(:parent) do
        build("Parent", parent: described_class) do
          order :C, :B, :A
        end
      end

      it "returns an array of keys in the order they were defined" do
        expect(parent.subtypes).to eql([c, b, a])
      end
    end

    context "when ordered in reverse direction" do
      subject(:parent) do
        build("Parent", parent: described_class) do
          order :A, :B, :C
        end
      end

      it "returns an array of keys in the order they were defined" do
        expect(parent.subtypes).to eql([a, b, c])
      end
    end
  end

  describe "::call" do
    context "given an abstraction" do
      subject(:animal) { self.class::Animal }

      class self::Animal < Dry::Interface
      end

      class self::Dog < self::Animal::Unit
        attribute :id, Value(:dog)
      end

      class self::Cat < self::Animal::Unit
        attribute :id, Value(:cat)
      end

      context "when all inputs fail" do
        subject(:result) { animal.call(:fish) }

        it "raises an error" do
          expect { result }.to raise_error(Dry::Types::MultipleError) do |e|
            expect(e.errors.count).to eq(2)
          end
        end
      end

      context "when last input passes" do
        subject(:result) { animal.call(:cat) }

        it { is_expected.to be_a(self.class::Cat) }
      end

      context "when first input passes" do
        subject(:result) { animal.call(:dog) }

        it { is_expected.to be_a(self.class::Dog) }
      end
    end

    context "with default value" do
      let(:default) { "value" }

      context "when callable" do
        let(:struct) { attribute :field, String, default: wrapper }
        let(:invalid) { { field: [] } }

        context "when callable returns wrong type" do
          let(:wrapper) { -> { :symbol } }

          it "raises an error" do
            expect { struct.call({}) }.to raise_error(Dry::Struct::Error)
          end
        end

        context "when callable returns correct type" do
          context "with key" do
            let(:wrapper) { -> { default } }

            it_behaves_like "a struct" do
              let(:valid) { { field: "string" } }
            end
          end

          context "without key" do
            let(:valid) { {} }

            context "when lambda" do
              let(:wrapper) { -> { default } }

              it_behaves_like "a struct" do
                it "contains default value" do
                  expect(result).to have_attributes(field: default)
                end
              end
            end

            context "when proc" do
              let(:wrapper) { proc { default } }

              it_behaves_like "a struct" do
                it "contains default value" do
                  expect(result).to have_attributes(field: default)
                end
              end
            end
          end
        end
      end

      context "when not callable" do
        let(:struct) { attribute :field, String, default: default }
        let(:invalid) { { field: [] } }

        context "with key" do
          it_behaves_like "a struct" do
            let(:valid) { { field: "string" } }
          end
        end

        context "without key" do
          it_behaves_like "a struct" do
            let(:valid) { {} }

            it "contains default value" do
              expect(result).to have_attributes(field: default)
            end
          end
        end
      end
    end

    context "with constrains" do
      let(:struct) { attribute :field, [String], min_size: 1 }

      it_behaves_like "a struct" do
        let(:valid) { { field: ["string"] } }
        let(:invalid) { { field: [] } }
      end
    end

    context "with constrains & default value" do
      let(:struct) { attribute :field, [String], min_size: 1, default: default }
      let(:default) { ["string"] }

      context "with key" do
        it_behaves_like "a struct" do
          let(:invalid) { { field: "string" } }
          let(:valid) { {} }

          it "contains default value" do
            expect(result).to have_attributes(field: default)
          end
        end
      end

      context "without key" do
        let(:valid) { { field: %w[value1 value2] } }

        it_behaves_like "a struct" do
          let(:invalid) { { field: [] } }
        end

        it_behaves_like "a struct" do
          let(:invalid) { { field: [:symbol] } }
        end
      end
    end

    context "with dry type" do
      it_behaves_like "a struct" do
        # Needed to make {Strict::String} accessible
        class self::Struct < described_class
          attribute :field, Strict::String
        end

        let(:struct) { self.class::Struct }
        let(:invalid) { { field: :symbol } }
        let(:valid) { { field: "string" } }
      end
    end

    context "with array type" do
      context "when none" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, [] }
          let(:invalid) { { field: "string" } }
          let(:valid) { { field: [] } }
        end
      end

      context "when single" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, [Integer] }
          let(:valid) { { field: [10, 20] } }
          let(:invalid) { { field: ["10.0"] } }
        end
      end

      context "when multiply" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, [Integer, Float] }
          let(:invalid) { { field: ["10.0"] } }
          let(:valid) { { field: [10.0, 10] } }
        end
      end

      context "when nested" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, [[String]] }
          let(:invalid) { { field: ["string"] } }
          let(:valid) { { field: [["string"]] } }
        end
      end
    end

    context "with hash type" do
      xcontext "when empty" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, {} }
          let(:invalid) { { field: [] } }
          let(:valid) { { field: {} } }
        end
      end

      context "when class" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, Hash }
          let(:invalid) { { field: [] } }
          let(:valid) { { field: {} } }
        end
      end

      context "with dynamic value" do
        context "with dynamic key" do
          it_behaves_like "a struct" do
            let(:struct) { attribute :field, { Integer => Integer } }
            let(:valid) { { field: { 100 => 100 } } }
            let(:invalid) { { field: { 100 => :other } } }
          end
        end

        context "with fixed key" do
          context "when symbol" do
            let(:struct) { attribute :field, { key: Integer } }

            it "raises an error" do
              expect { struct }.to raise_error(ArgumentError)
            end
          end

          context "when type" do
            let(:struct) do
              define_struct do
                attribute :field, { Value(:key) => Integer }
              end
            end

            let(:valid) { { field: { key: 100 } } }

            it_behaves_like "a struct" do
              let(:invalid) { { field: { other: 100 } } }
            end

            it_behaves_like "a struct" do
              let(:invalid) { { field: { key: :string } } }
            end
          end
        end
      end

      context "with fixed value" do
        context "with dynamic key" do
          it_behaves_like "a struct" do
            let(:struct) do
              define_struct do
                attribute :field, { Integer => Value(:value) }
              end
            end

            let(:valid) { { field: { 100 => :value } } }
            let(:invalid) { { field: { 100 => :other } } }
          end
        end

        context "with fixed key" do
          context "when symbol" do
            let(:struct) { attribute :field, { key: :value } }

            it "raises an error" do
              expect { struct }.to raise_error(ArgumentError)
            end
          end

          context "when type" do
            let(:struct) do
              define_struct do
                attribute :field, { Value(:key) => Value(:value) }
              end
            end

            let(:valid) { { field: { key: :value } } }

            it_behaves_like "a struct" do
              let(:invalid) { { field: { key: "string" } } }
            end

            it_behaves_like "a struct" do
              let(:invalid) { { field: { other: :value } } }
            end
          end
        end
      end
    end

    context "with primitive type" do
      context "when single" do
        it_behaves_like "a struct" do
          let(:struct) { attribute :field, Integer }
          let(:valid) { { field: 10 } }
          let(:invalid) { { field: "10.0" } }
        end
      end

      context "when multiply" do
        let(:invalid) { { field: "10.0" } }

        context "without options" do
          let(:struct) { attribute :field, Integer, Float }

          it_behaves_like "a struct" do
            let(:valid) { { field: 10.0 } }
          end

          it_behaves_like "a struct" do
            let(:valid) { { field: 10 } }
          end
        end

        context "with options" do
          let(:struct) { attribute :field, Integer, Float, default: 0 }

          it_behaves_like "a struct" do
            let(:valid) { { field: 10.0 } }
          end

          it_behaves_like "a struct" do
            let(:valid) { { field: 10 } }
          end

          it_behaves_like "a struct" do
            let(:valid) { {} }

            it "returns default value" do
              expect(result).to have_attributes(field: 0)
            end
          end
        end
      end
    end
  end
end

describe Dry::Interface do
  describe "::call" do
    context "when inheriting directly from interface" do
      class self::Parent < described_class
        attribute :id, Types.Value(:parent)
      end

      class self::Child < self::Parent::Concrete
        attribute :id, Types.Value(:child)
      end

      subject { self.class::Parent.call(id: :child) }

      it { is_expected.to be_a(self.class::Child) }
    end

    context "when inheriting directly value" do
      context "when child contains two attributes" do
        class self::Parent < described_class
          attribute :id, Types.Value(:parent)
        end

        class self::Child < self::Parent::Unit
          attribute :id1, Types.Value(:child)
          attribute :id2, Types.Value(:child)
        end

        it "raises an argument error" do
          expect { self.class::Child.call(:child) }.to raise_error(ArgumentError)
        end
      end

      context "when child contains one attribute" do
        class self::Parent < described_class
          attribute :id, Types.Value(:parent)
        end

        class self::Child < self::Parent::Unit
          attribute :id, Types.Value(:child)
        end

        context "when input is a value" do
          subject { self.class::Parent.call(:child) }

          it { is_expected.to be_a(self.class::Child) }
        end

        context "when input is a hash" do
          subject { self.class::Parent.call(id: :child) }

          it { is_expected.to be_a(self.class::Child) }
        end

        context "when input is an instance" do
          subject { self.class::Parent.call(child) }

          let(:child) { self.class::Parent.call(id: :child) }

          it { is_expected.to be_a(self.class::Child) }
        end
      end
    end

    context "given a concrete sub class" do
      class self::Parent < described_class::Concrete
        attribute :id, Types.Value(:parent)
      end

      subject { self.class::Parent.call(id: :parent) }

      it { is_expected.to be_a(self.class::Parent) }
    end

    context "given a abstract sub class" do
      class self::Parent < described_class::Abstract
        attribute :id, Types.Value(:parent)
      end

      context "when given concrete children" do
        class self::Child1 < self::Parent::Concrete
          attribute :id, Types.Value(:child1)
        end

        class self::Child2 < self::Parent::Concrete
          attribute :id, Types.Value(:child2)
        end

        context "when referencing child 1" do
          subject { self.class::Parent.call(id: :child1) }

          it { is_expected.to be_a(self.class::Child1) }
        end
      end
    end
  end

  describe described_class do
    describe "::name" do
      class self::Parent < described_class
      end

      subject { self.class::Parent }

      class self::AbstractChild1 < self::Parent::Abstract
      end

      class self::Child1 < self::Parent::Concrete
      end

      class self::Sub1 < self::AbstractChild1::Concrete
      end

      class self::Sub2 < self::AbstractChild1::Concrete
      end

      it { is_expected.to have_attributes(to_s: end_with("::Parent<[AbstractChild1<[Sub1 | Sub2]> | Child1]>")) }
    end
  end

  describe "::subtypes" do
    context "when concrete" do
      class self::Parent < described_class::Concrete
      end

      subject { self.class::Parent }

      it { is_expected.to have_attributes(subtypes: []) }
    end

    context "when abstract" do
      class self::Parent < described_class::Abstract
      end

      subject(:parent) { self.class::Parent }

      context "when subtype is concrete" do
        class self::Child1 < self::Parent::Concrete
        end

        class self::Child2 < self::Parent::Concrete
        end

        let(:child1) { self.class::Child1 }
        let(:child2) { self.class::Child2 }

        it { is_expected.to have_attributes(subtypes: include(child1, child2)) }
      end

      context "when subtype is abstract" do
        class self::Child1 < self::Parent::Abstract
        end

        class self::Child2 < self::Parent::Abstract
        end

        let(:child1) { self.class::Child1 }
        let(:child2) { self.class::Child2 }

        it { is_expected.to have_attributes(subtypes: include(child1, child2)) }

        context "when child is inherited" do
          class self::SubChild < self::Child1::Concrete
          end

          subject { self.class::Child1 }

          let(:subchild) { self.class::SubChild }

          it { is_expected.to have_attributes(subtypes: include(subchild)) }

          it "s parent does not include subchild" do
            expect(parent.subtypes).not_to include(subchild)
          end
        end
      end
    end
  end
end
