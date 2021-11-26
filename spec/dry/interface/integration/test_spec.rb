# frozen_string_literal: true

module Test
  # Dry::Interface::Interfaces::Abstract
  class Animal < Dry::Interface
    # Dry::Interface::Interfaces::Concrete
    # Dry::Interface::Interfaces::Concrete::ClassMethods
    class Mammal < Concrete
      attribute :id, Value(:mammal)
    end

    # Dry::Interface::Interfaces::Concrete

    # Dry::Interface::Interfaces::Value::ClassMethods
    class Bird < Unit
      attribute :id, Value(:bird)
    end

    # Dry::Interface::Interfaces::Abstract
    # Dry::Interface::Interfaces::Abstract::ClassMethods
    class Fish < Abstract
      class Whale < Unit
        attribute :id, Value(:whale)
      end

      class Shark < Unit
        attribute :id, Value(:shark)
      end
    end
  end
end

describe Test do
  subject { described_class }

  describe described_class::Animal do
    it { is_expected.to have_attributes(to_s: include("Animal")) }
    it { is_expected.to have_attributes(to_s: include("Bird")) }
    it { is_expected.to have_attributes(to_s: include("Mammal")) }
    it { is_expected.to have_attributes(to_s: include("Fish")) }
    it { is_expected.to have_attributes(to_s: include("Whale")) }

    describe "::call" do
      context "when called with a hash" do
        subject { described_class.call(id: :bird) }

        it { is_expected.to be_a(described_class::Bird) }
      end

      xcontext "when called with an id" do
        subject { described_class.call(:whale) }

        it { is_expected.to be_a(described_class::Fish::Whale) }
      end
    end

    describe "::new" do
      context "when called with a hash" do
        subject { described_class.call(id: :bird) }

        it { is_expected.to be_a(described_class::Bird) }
      end

      xcontext "when called with an id" do
        subject { described_class.call(:whale) }

        it { is_expected.to be_a(described_class::Fish::Whale) }
      end
    end

    describe described_class::Fish do
      it { is_expected.to have_attributes(name: include("Fish")) }

      describe "::call" do
        subject { described_class.call(id: :whale) }

        it { is_expected.to be_a(described_class::Whale) }
      end

      describe "::new" do
        subject { described_class.call(id: :shark) }

        it { is_expected.to be_a(described_class::Shark) }
      end
    end

    describe described_class::Mammal do
      it { is_expected.to have_attributes(name: include("Mammal")) }

      describe "::call" do
        subject { described_class.call(id: :mammal) }

        it { is_expected.to be_a(described_class) }
      end
    end

    describe described_class::Bird do
      it { is_expected.to have_attributes(name: include("Bird")) }

      describe "::call" do
        context "when called with a hash" do
          subject { described_class.call(id: :bird) }

          it { is_expected.to be_a(described_class) }
        end

        context "when called with an id" do
          subject { described_class.call(:bird) }

          it { is_expected.to be_a(described_class) }
        end
      end

      describe "::new" do
        context "when called with a hash" do
          subject { described_class.call(id: :bird) }

          it { is_expected.to be_a(described_class) }
        end

        context "when called with an id" do
          subject { described_class.call(:bird) }

          it { is_expected.to be_a(described_class) }
        end
      end
    end
  end
end
