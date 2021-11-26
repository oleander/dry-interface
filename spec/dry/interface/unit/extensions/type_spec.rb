# frozen_string_literal: true

describe Dry::Interface::Extensions::Type do
  using described_class

  describe "#to_type" do
    let(:constructor) { described_class }
    let(:type) { constructor.to_type }

    context "when given a primitive ruby class" do
      context "when defined by dry types" do
        describe String do
          it_behaves_like "a dry type"
          it_behaves_like "a type" do
            let(:valid) { "string" }
            let(:invalid) { :symbol }
          end
        end

        describe Hash do
          it_behaves_like "a dry type"
          it_behaves_like "a type" do
            let(:valid) { { key: "value" } }
            let(:invalid) { :symbol }
          end
        end

        describe Array do
          it_behaves_like "a dry type"
          it_behaves_like "a type" do
            let(:valid) { ["string", :symbol] }
            let(:invalid) { { key: "value" } }
          end
        end

        describe Float do
          it_behaves_like "a dry type"
          it_behaves_like "a type" do
            let(:valid) { 100.0 }
            let(:invalid) { 100 }
          end
        end
      end

      context "when given a dry types reference" do
        context "when it exists" do
          it_behaves_like "a type", String do
            let(:constructor) { "strict.string" }
            let(:valid) { "string" }
            let(:invalid) { :symbol }
          end

          it_behaves_like "a type", Symbol do
            let(:constructor) { "coercible.symbol" }
            let(:valid) { "string" }
            let(:invalid) { 10 }
          end

          it_behaves_like "a type", String do
            let(:constructor) { "string" }
            let(:valid) { "string" }
            let(:invalid) { :symbol }
          end
        end

        context "when it does not exist" do
          context "when string" do
            it "raises an error" do
              expect { "does-not-exist".to_type }.to raise_error(ArgumentError)
            end
          end

          context "when nil" do
            it "raises an error" do
              expect { nil.to_type }.to raise_error(ArgumentError)
            end
          end

          context "when symbol" do
            it "raises an error" do
              expect { :doesnotexist.to_type }.to raise_error(ArgumentError)
            end
          end
        end
      end

      context "when not defined by dry types" do
        context "when it takes arguments" do
          describe Set do
            it_behaves_like "a ruby type"
            it_behaves_like "a type" do
              let(:invalid) { 1 }
              let(:valid) { [1, 2, 3] }
            end
          end

          describe Pathname do
            it_behaves_like "a ruby type"
            it_behaves_like "a type" do
              let(:invalid) { :symbol }
              let(:valid) { "/a/b/c.txt" }
            end
          end
        end

        xcontext "when it does not take arguments" do
          describe Mutex do
            it_behaves_like "a type without args"
            it_behaves_like "a ruby type"
          end
        end
      end
    end

    context "when given an array" do
      context "when typed" do
        describe [String] do
          it_behaves_like "a type" do
            let(:valid) { ["string"] }
            let(:invalid) { [:symbol] }
          end
        end
      end

      context "when not typed" do
        describe [] do
          it_behaves_like "a type" do
            let(:valid) { [] }
            let(:invalid) { "string" }
          end

          it_behaves_like "a type" do
            let(:valid) { [[]] }
            let(:invalid) { "string" }
          end
        end
      end

      context "when multiply types" do
        describe [String, Symbol] do
          it_behaves_like "a type" do
            let(:valid) { ["string", :symbol] }
            let(:invalid) { [Object.new] }
          end
        end
      end

      context "when deeply nested" do
        describe [[String, Symbol]] do
          let(:valid) { [["string", :symbol]] }

          it_behaves_like "a type" do
            let(:invalid) { [[Object.new]] }
          end

          it_behaves_like "a type" do
            let(:invalid) { [Object.new] }
          end

          it_behaves_like "a type" do
            let(:invalid) { nil }
          end
        end

        describe [[[String], Symbol]] do
          it_behaves_like "a type" do
            let(:valid) { [[["string"], :symbol]] }
            let(:invalid) { [["string", :symbol]] }
          end
        end

        describe [[[], Symbol]] do
          it_behaves_like "a type" do
            let(:valid) { [[[:symbol], :symbol]] }
            let(:invalid) { [["string", :symbol]] }
          end
        end
      end
    end

    context "when given a dry type" do
      describe Types::String do
        it_behaves_like "a type", String do
          let(:valid) { "string" }
          let(:invalid) { :symbol }
        end
      end

      context "when wrapped in an array" do
        context "when one layer deep" do
          describe [Types::String] do
            it_behaves_like "a type" do
              let(:valid) { ["string"] }
              let(:invalid) { [:symbol] }
            end
          end
        end

        context "when two layers deep" do
          describe [[Types::String]] do
            let(:valid) { [["string"]] }

            it_behaves_like "a type" do
              let(:invalid) { [[:symbol]] }
            end

            it_behaves_like "a type" do
              let(:invalid) { ["string"] }
            end
          end
        end

        context "when combined with primitive class" do
          describe [Types::String, Hash] do
            let(:valid) { [{}, "string"] }

            it_behaves_like "a type" do
              let(:invalid) { [[], "string"] }
            end

            it_behaves_like "a type" do
              let(:invalid) { ["string", []] }
            end
          end
        end
      end
    end

    context "when given a non-native class" do
      context "when dry struct" do
        class self::MyStruct < Dry::Struct
          attribute :name, "string"
        end

        xdescribe self::MyStruct do
          it_behaves_like "a type" do
            let(:valid) { { name: "john" } }
            let(:invalid) { { name: :john } }
          end
        end
      end

      context "when class has an invalid name" do
        self::MyClass = Class.new do
          def self.name
            "invalid-name"
          end
        end

        xdescribe self::MyClass do
          subject { type.call }

          it { is_expected.to be_a(described_class) }
        end
      end

      context "when not dry struct" do
        context "with constructor parameters" do
          self::Struct = Struct.new(:value, keyword_init: true)

          let(:invalid) { ["an array"] }

          context "when passed a hash" do
            describe self::Struct do
              it_behaves_like "a type" do
                let(:valid) { { value: "john" } }
              end
            end
          end

          context "when passed an instance of the type" do
            describe self::Struct do
              it_behaves_like "a type" do
                let(:valid) { self.class::Struct.new(value: "string") }
              end
            end
          end
        end

        context "without constructor parameters" do
          xdescribe Class.new do
            context "with no input" do
              subject { type.call }

              it { is_expected.to be_a(described_class) }
            end

            context "with input" do
              it "raises an error" do
                expect { type.call({ value: "value" }) }.to raise_error(Dry::Types::CoercionError)
              end
            end
          end
        end
      end
    end

    context "when given a hash" do
      context "when empty" do
        describe({}) do
          let(:invalid) { Object.new }

          it_behaves_like "a type" do
            let(:valid) { {} }
          end

          it_behaves_like "a type" do
            let(:valid) { { key: "value" } }
          end
        end
      end

      context "with typed keys" do
        describe({ String => String }) do
          let(:valid) { { "string" => "string" } }

          it_behaves_like "a type" do
            let(:invalid) { { "key" => :symbol } }
          end

          it_behaves_like "a type" do
            let(:invalid) { { symbol: "string" } }
          end
        end
      end

      context "when fixed keys" do
        context "when fixed values" do
          describe({ Value(:key) => Value("value") }) do
            let(:valid) { { key: "value" } }

            it_behaves_like "a type" do
              let(:invalid) { { something: "value" } }
            end

            it_behaves_like "a type" do
              let(:invalid) { { key: "something" } }
            end
          end
        end

        describe({ Value(:key) => Value("value") }) do
          let(:valid) { { key: "value" } }

          it_behaves_like "a type" do
            let(:invalid) { { something: "value" } }
          end

          it_behaves_like "a type" do
            let(:invalid) { { key: "something" } }
          end
        end

        context "when value is primitive type" do
          describe({ Value(:key) => String }) do
            let(:valid) { { key: "value" } }

            it_behaves_like "a type" do
              let(:invalid) { { key: :symbol } }
            end
          end
        end

        context "when value is a constructor" do
          context "when dry struct" do
            class self::Struct < Dry::Struct
              attribute :name, "string"
            end

            describe({ Value(:key) => self::Struct }) do
              let(:valid) { { key: { name: "John" } } }

              it_behaves_like "a type" do
                let(:invalid) { { key: :symbol } }
              end

              it_behaves_like "a type" do
                let(:invalid) { { key: { name: :John } } }
              end
            end
          end

          context "when given a native struct" do
            describe Struct.new(:value, keyword_init: true) do
              let(:valid) { { value: "value" } }

              it_behaves_like "a type" do
                let(:invalid) { Object.new }

                it "returns sets attribute" do
                  expect(type.call(valid)).to be_a(described_class).and have_attributes(valid)
                end
              end

              it_behaves_like "a type" do
                let(:invalid) { { hello: "value" } }
              end
            end
          end

          context "when regular class" do
            self::MyClass = Struct.new(:value)

            describe({ Value(:key) => self::MyClass }) do
              it_behaves_like "a type" do
                let(:invalid) { Object.new }
                let(:valid) { { key: "value" } }

                it "sets class" do
                  expect(type.call(valid)).to be_a(Hash).and include(
                    key: be_an_instance_of(self.class::MyClass).and(have_attributes(value: "value"))
                  )
                end
              end
            end
          end
        end
      end
    end

    context "when given a module" do
      describe Enumerable do
        it_behaves_like "a type" do
          let(:valid) { [1, 2, 3] }
          let(:invalid) { Object.new }

          it "returns input" do
            expect(type.call(valid)).to eq(valid)
          end
        end
      end
    end
  end
end
