# frozen_string_literal: true

describe Dry::Interface do
  describe "::call" do
    context "with default value" do
      let(:default) { "value" }

      context "when callable" do
        let(:struct) { attribute :field, String, default: wrapper }
        let(:invalid) { { field: [] } }

        context "when callable returns wrong type" do
          let(:wrapper) { -> { :symbol } }

          it "raises an error" do
            expect { struct.call({}) }.to raise_error(described_class::Error)
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
