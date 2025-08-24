# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema do
  # ===========================================
  # PRIMITIVE TYPES TESTS
  # ===========================================
  describe "primitive types" do
    let(:schema_class) { Class.new(described_class) }

    it "supports string type with enum and description" do
      schema_class.string :status, enum: %w[active inactive], description: "Status field"

      properties = schema_class.properties
      expect(properties[:status]).to eq({
        type: "string",
        enum: %w[active inactive],
        description: "Status field"
      })
    end

    it "supports string type with additional properties" do
      schema_class.string :email, format: "email", min_length: 5, max_length: 100, pattern: "\\S+@\\S+", description: "Email field"

      properties = schema_class.properties
      expect(properties[:email]).to eq({
        type: "string",
        format: "email",
        minLength: 5,
        maxLength: 100,
        pattern: "\\S+@\\S+",
        description: "Email field"
      })
    end

    it "supports number type with constraints" do
      schema_class.number :price, minimum: 0, maximum: 1000, multiple_of: 0.01, description: "Price field"

      properties = schema_class.properties
      expect(properties[:price]).to eq({
        type: "number",
        minimum: 0,
        maximum: 1000,
        multipleOf: 0.01,
        description: "Price field"
      })
    end

    it "supports number type with description" do
      schema_class.number :price, description: "Price field"

      properties = schema_class.properties
      expect(properties[:price]).to eq({type: "number", description: "Price field"})
    end

    it "supports integer type with description" do
      schema_class.integer :count, description: "Count value"

      properties = schema_class.properties
      expect(properties[:count]).to eq({type: "integer", description: "Count value"})
    end

    it "supports boolean type with description" do
      schema_class.boolean :enabled, description: "Enabled field"

      properties = schema_class.properties
      expect(properties[:enabled]).to eq({type: "boolean", description: "Enabled field"})
    end

    it "supports null type with description" do
      schema_class.null :placeholder, description: "Null field"

      properties = schema_class.properties
      expect(properties[:placeholder]).to eq({type: "null", description: "Null field"})
    end

    it "handles required vs optional properties" do
      schema_class.string :required_field
      schema_class.string :optional_field, required: false

      expect(schema_class.required_properties).to include(:required_field)
      expect(schema_class.required_properties).not_to include(:optional_field)
    end
  end

  # ===========================================
  # ARRAY TYPES TESTS
  # ===========================================
  describe "array types" do
    let(:schema_class) { Class.new(described_class) }

    it "supports arrays with primitive types and descriptions" do
      schema_class.array :strings, of: :string, description: "String array"
      schema_class.array :numbers, of: :number
      schema_class.array :integers, of: :integer
      schema_class.array :booleans, of: :boolean

      properties = schema_class.properties

      expect(properties[:strings]).to eq({type: "array", items: {type: "string"}, description: "String array"})
      expect(properties[:numbers]).to eq({type: "array", items: {type: "number"}})
      expect(properties[:integers]).to eq({type: "array", items: {type: "integer"}})
      expect(properties[:booleans]).to eq({type: "array", items: {type: "boolean"}})
    end

    it "supports arrays with constraints" do
      schema_class.array :strings, of: :string, min_items: 1, max_items: 10, description: "String array"

      properties = schema_class.properties
      expect(properties[:strings]).to eq({type: "array", items: {type: "string"}, minItems: 1, maxItems: 10, description: "String array"})
    end

    it "supports arrays with object definitions" do
      schema_class.array :items do
        object do
          string :name
          integer :value
        end
      end

      properties = schema_class.properties
      expect(properties[:items][:items]).to include(
        type: "object",
        properties: {
          name: {type: "string"},
          value: {type: "integer"}
        },
        required: %i[name value],
        additionalProperties: false
      )
    end

    it "supports arrays with references to defined schemas" do
      schema_class.define :product do
        string :name
        number :price
      end

      schema_class.array :products, of: :product

      properties = schema_class.properties
      expect(properties[:products]).to eq({
        type: "array",
        items: {"$ref" => "#/$defs/product"}
      })
    end

    it "supports arrays of anyOf types" do
      schema_class.array :items do
        any_of :value do
          string :alphanumeric
          number :numeric
        end
      end
    end
  end

  # ===========================================
  # OBJECT AND NESTING TESTS
  # ===========================================
  describe "object types and nesting" do
    let(:schema_class) { Class.new(described_class) }

    it "supports nested objects with mixed property types" do
      schema_class.object :address do
        string :street
        string :city
        integer :zip_code, required: false
      end

      properties = schema_class.properties
      expect(properties[:address]).to include(
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"},
          zip_code: {type: "integer"}
        },
        required: %i[street city],
        additionalProperties: false
      )
    end

    it "supports deeply nested objects" do
      schema_class.object :level1 do
        object :level2 do
          object :level3 do
            string :deep_value
          end
        end
      end

      instance = schema_class.new
      properties = instance.to_json_schema[:schema][:properties]

      level3 = properties[:level1][:properties][:level2][:properties][:level3]
      expect(level3[:properties][:deep_value]).to eq({type: "string"})
    end

    it "supports any_of with mixed types including objects" do
      schema_class.any_of :flexible_field do
        string enum: %w[option1 option2]
        integer
        object do
          string :nested_field
        end
        null
      end

      properties = schema_class.properties
      any_of_schemas = properties[:flexible_field][:anyOf]

      expect(any_of_schemas).to include(
        {type: "string", enum: %w[option1 option2]},
        {type: "integer"},
        {type: "null"}
      )

      object_schema = any_of_schemas.find { |s| s[:type] == "object" }
      expect(object_schema[:properties][:nested_field]).to eq({type: "string"})
    end

    it "supports reference to a defined schema by block" do
      schema_class.define :address do
        string :street
        string :city
      end

      schema_class.object :user do
        string :name
        object :address do
          reference :address
        end
      end

      instance = schema_class.new
      json_output = instance.to_json_schema

      expect(json_output[:schema][:properties][:user][:properties][:address]).to eq({"$ref" => "#/$defs/address"})
      expect(json_output[:schema]["$defs"][:address]).to eq({
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"}
        },
        required: %i[street city],
        additionalProperties: false
      })
    end

    it "supports reference to a defined schema by reference option" do
      schema_class.define :address do
        string :street
        string :city
      end

      schema_class.object :user do
        string :name
        object :address, reference: :address
      end

      instance = schema_class.new
      json_output = instance.to_json_schema

      expect(json_output[:schema][:properties][:user][:properties][:address]).to eq({"$ref" => "#/$defs/address"})
      expect(json_output[:schema]["$defs"][:address]).to eq({
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"}
        },
        required: %i[street city],
        additionalProperties: false
      })
    end
  end

  # ===========================================
  # DEFINITIONS AND REFERENCES
  # ===========================================
  describe "definitions and references" do
    let(:schema_class) { Class.new(described_class) }

    it "supports defining and referencing reusable schemas" do
      schema_class.define :address do
        string :street
        string :city
      end

      schema_class.object :user do
        string :name
        array :addresses, of: :address
      end

      ref_hash = schema_class.reference(:address)
      expect(ref_hash).to eq({"$ref" => "#/$defs/address"})

      instance = schema_class.new
      json_output = instance.to_json_schema

      # Check definition
      expect(json_output[:schema]["$defs"][:address]).to include(
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"}
        },
        required: %i[street city]
      )

      # Check reference usage
      user_props = json_output[:schema][:properties][:user][:properties]
      expect(user_props[:addresses][:items]).to eq({"$ref" => "#/$defs/address"})
    end

    it "supports reference to the root schema" do
      schema_class.string :element_type, enum: ["input", "button"]
      schema_class.string :label
      schema_class.object :sub_schema, reference: :root

      instance = schema_class.new
      json_output = instance.to_json_schema

      expect(json_output[:schema][:properties][:sub_schema]).to eq({"$ref" => "#"})
    end
  end

  # ===========================================
  # INSTANCE METHODS TESTS
  # ===========================================
  describe "instance methods" do
    let(:schema_class) { Class.new(described_class) }

    it "handles naming correctly" do
      # Named class
      stub_const("TestSchemaClass", Class.new(described_class))
      named_instance = TestSchemaClass.new
      expect(named_instance.to_json_schema[:name]).to eq("TestSchemaClass")

      # Anonymous class
      anonymous_instance = schema_class.new
      expect(anonymous_instance.to_json_schema[:name]).to eq("Schema")

      # Provided name
      custom_instance = schema_class.new("CustomName")
      expect(custom_instance.to_json_schema[:name]).to eq("CustomName")

      # Provided description
      described_instance = schema_class.new("TestName", description: "Custom description")
      expect(described_instance.to_json_schema[:description]).to eq("Custom description")
    end

    it "supports method delegation for schema methods" do
      instance = schema_class.new

      expect(instance).to respond_to(:string, :number, :integer, :boolean, :array, :object, :any_of, :null)
      expect(instance).not_to respond_to(:unknown_method)
    end

    it "produces correctly structured JSON schema and JSON output" do
      schema_class.string :name
      schema_class.integer :age, required: false

      instance = schema_class.new("TestSchema")
      json_output = instance.to_json_schema

      expect(json_output).to include(
        name: "TestSchema",
        description: nil,
        schema: hash_including(
          type: "object",
          properties: {
            name: {type: "string"},
            age: {type: "integer"}
          },
          required: [:name],
          additionalProperties: false,
          strict: true
        )
      )

      # Test JSON string output
      json_string = instance.to_json
      expect(json_string).to be_a(String)
      parsed_json = JSON.parse(json_string)
      expect(parsed_json["name"]).to eq("TestSchema")
    end
  end

  # ===========================================
  # ERROR HANDLING TESTS
  # ===========================================
  describe "error handling" do
    let(:schema_class) { Class.new(described_class) }

    it "raises appropriate errors for invalid configurations" do
      # Unknown schema type
      expect {
        schema_class.build_property_schema(:unknown_type)
      }.to raise_error(RubyLLM::Schema::InvalidSchemaTypeError, "Unknown schema type: unknown_type")

      # Invalid array types
      expect {
        schema_class.array :items, of: 123
      }.to raise_error(RubyLLM::Schema::InvalidArrayTypeError, "Invalid array type: 123")

      expect {
        schema_class.array :items, of: "invalid"
      }.to raise_error(RubyLLM::Schema::InvalidArrayTypeError, "Invalid array type: invalid")
    end

    it "accepts symbols as references (even if undefined)" do
      expect {
        schema_class.array :items, of: :undefined_reference
      }.not_to raise_error

      properties = schema_class.properties
      expect(properties[:items][:items]).to eq({"$ref" => "#/$defs/undefined_reference"})
    end
  end

  # ===========================================
  # VALIDATION TESTS
  # ===========================================
  describe "validation" do
    let(:schema_class) { Class.new(described_class) }

    describe "circular reference detection" do
      it "detects direct circular references" do
        schema_class.define :user do
          string :name
        end

        # Create a direct circular reference
        schema_class.definitions[:user][:properties][:self_ref] = schema_class.reference(:user)

        expect(schema_class.valid?).to be false
        expect { schema_class.validate! }.to raise_error(
          RubyLLM::Schema::ValidationError,
          /Circular reference detected involving 'user'/
        )
      end

      it "detects indirect circular references" do
        schema_class.define :user do
          string :name
        end

        schema_class.define :profile do
          string :bio
        end

        # Create circular chain: user -> profile -> user
        schema_class.definitions[:user][:properties][:profile] = schema_class.reference(:profile)
        schema_class.definitions[:profile][:properties][:owner] = schema_class.reference(:user)

        expect(schema_class.valid?).to be false
        expect { schema_class.validate! }.to raise_error(
          RubyLLM::Schema::ValidationError,
          /Circular reference detected involving/
        )
      end
    end

    describe "validation guards for JSON generation" do
      it "prevents JSON generation for schemas with circular references" do
        schema_class.define :user do
          string :name
        end

        # Add circular reference
        schema_class.definitions[:user][:properties][:self_ref] = schema_class.reference(:user)

        instance = schema_class.new
        expect { instance.to_json_schema }.to raise_error(RubyLLM::Schema::ValidationError)
        expect { instance.to_json }.to raise_error(RubyLLM::Schema::ValidationError)
      end
    end
  end

  # ===========================================
  # COMPREHENSIVE SCENARIOS
  # ===========================================
  describe "comprehensive scenarios" do
    it "handles edge cases" do
      # Empty schema
      empty_schema = Class.new(described_class)
      empty_instance = empty_schema.new("EmptySchema")
      empty_output = empty_instance.to_json_schema

      expect(empty_output[:schema][:properties]).to eq({})
      expect(empty_output[:schema][:required]).to eq([])

      # Schema with only optional properties
      optional_schema = Class.new(described_class) do
        string :optional1, required: false
        integer :optional2, required: false
      end

      optional_instance = optional_schema.new
      optional_output = optional_instance.to_json_schema

      expect(optional_output[:schema][:required]).to eq([])
      expect(optional_output[:schema][:properties].keys).to contain_exactly(:optional1, :optional2)
    end

    it "handles complex nested structures with all features" do
      complex_schema = Class.new(described_class) do
        string :id, description: "Unique identifier"

        object :metadata do
          string :created_by
          integer :version
          boolean :published, required: false
        end

        array :tags, of: :string, description: "Resource tags"

        array :items do
          object do
            string :name
            any_of :value do
              string
              number
              boolean
              null
            end
          end
        end

        any_of :status do
          string enum: %w[draft published]
          null
        end

        define :author do
          string :name
          string :email
        end

        array :authors, of: :author
      end

      instance = complex_schema.new("ComplexSchema")
      json_output = instance.to_json_schema

      # Verify comprehensive structure
      expect(json_output[:schema][:properties].keys).to contain_exactly(
        :id, :metadata, :tags, :items, :status, :authors
      )
      expect(json_output[:schema]["$defs"][:author]).to be_a(Hash)
      expect(json_output[:schema][:required]).to include(:id, :metadata, :tags, :items, :status, :authors)

      # Verify descriptions are preserved
      expect(json_output[:schema][:properties][:id][:description]).to eq("Unique identifier")
      expect(json_output[:schema][:properties][:tags][:description]).to eq("Resource tags")
    end
  end
end
