# frozen_string_literal: true

module Test
  class Animal < Dry::Interface
    class Mammal < Concrete
      attribute :id, Value(:mammal)
    end

    class Bird < Value
      attribute :id, Value(:bird)
    end

    class Fish < Abstract
      class Whale < Value
        attribute :id, Value(:whale)
      end

      class Shark < Value
        attribute :id, Value(:shark)
      end
    end
  end
end

describe Test do
  subject { described_class }

  describe described_class::Animal do
    it { is_expected.to have_attributes(named: include("Test::Animal")) }
    it { is_expected.to have_attributes(named: include("Bird")) }
    it { is_expected.to have_attributes(named: include("Mammal")) }
    it { is_expected.to have_attributes(named: include("Fish")) }
    it { is_expected.to have_attributes(named: include("Whale")) }

    describe "::call" do
      context "when called with a hash" do
        subject { described_class.call(id: :bird) }

        it { is_expected.to be_a(described_class::Bird) }
      end

      context "when called with an id" do
        subject { described_class.call(:whale) }

        it { is_expected.to be_a(described_class::Fish::Whale) }
      end
    end

    describe "::new" do
      context "when called with a hash" do
        subject { described_class.new(id: :bird) }

        it { is_expected.to be_a(described_class::Bird) }
      end

      context "when called with an id" do
        subject { described_class.new(:whale) }

        it { is_expected.to be_a(described_class::Fish::Whale) }
      end
    end

    describe described_class::Fish do
      it { is_expected.to have_attributes(named: include("Fish")) }

      describe "::call" do
        subject { described_class.call(id: :whale) }

        it { is_expected.to be_a(described_class::Whale) }
      end

      describe "::new" do
        subject { described_class.new(id: :shark) }

        it { is_expected.to be_a(described_class::Shark) }
      end
    end

    describe described_class::Mammal do
      it { is_expected.to have_attributes(named: include("Mammal")) }

      describe "::call" do
        subject { described_class.call(id: :mammal) }

        it { is_expected.to be_a(described_class) }
      end
    end

    describe described_class::Bird do
      it { is_expected.to have_attributes(named: include("Bird")) }

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
          subject { described_class.new(id: :bird) }

          it { is_expected.to be_a(described_class) }
        end

        context "when called with an id" do
          subject { described_class.new(:bird) }

          it { is_expected.to be_a(described_class) }
        end
      end
    end
  end
end
