# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema do
  describe ".create factory method" do
    let(:person_schema) do
      PersonSchema = described_class.create do
        string :name, description: "Person's name"
        number :age
        boolean :active, required: false
      end
    end

    let(:instance) { PersonSchema.new }
    let(:json_output) { instance.to_json_schema }

    it "creates a new Schema class" do
      expect(person_schema).to be < described_class
      expect(person_schema).not_to eq(described_class)

      expect(instance.class.name).to eq("PersonSchema")
      expect(json_output[:name]).to eq("PersonSchema")
    end

    it "defines properties correctly" do
      properties = json_output[:schema][:properties]
      
      expect(properties[:name]).to eq({type: "string", description: "Person's name"})
      expect(properties[:age]).to eq({type: "number"})
      expect(properties[:active]).to eq({type: "boolean"})
    end

    it "handles required properties correctly" do
      expect(json_output[:schema][:required]).to contain_exactly(:name, :age)
    end

    it "supports nested objects" do
      complex_schema = described_class.create do
        string :name
        object :address do
          string :street
          string :city
        end
      end

      instance = complex_schema.new
      properties = instance.to_json_schema[:schema][:properties]

      expect(properties[:address]).to include(
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"}
        },
        required: %i[street city],
        additionalProperties: false
      )
    end
  end

  describe "Helpers module" do
    include RubyLLM::Helpers

    let(:person_schema) do
      schema "PersonSchema" do
        string :name, description: "Person's name"
        number :age
        boolean :active, required: false
      end
    end

    let(:json_output) { person_schema.to_json_schema }

    it "creates a schema instance directly" do
      expect(person_schema).to be_a(RubyLLM::Schema)
      expect(person_schema).not_to be_a(Class)

      expect(json_output[:name]).to eq("PersonSchema")
    end

    it "sets name and description correctly" do
      expect(json_output[:name]).to eq("PersonSchema")
    end

    it "defines properties correctly" do
      properties = json_output[:schema][:properties]
      
      expect(properties[:name]).to eq({type: "string", description: "Person's name"})
      expect(properties[:age]).to eq({type: "number"})
      expect(properties[:active]).to eq({type: "boolean"})
    end

    it "handles required properties correctly" do
      expect(json_output[:schema][:required]).to contain_exactly(:name, :age)
    end

    it "works with minimal syntax" do
      simple_schema = schema do
        string :title
        number :count
      end

      properties = simple_schema.to_json_schema[:schema][:properties]
      expect(properties[:title]).to eq({type: "string"})
      expect(properties[:count]).to eq({type: "number"})
    end

    it "supports nested objects" do
      complex_schema = schema do
        string :name
        object :address do
          string :street
          string :city
        end
      end

      properties = complex_schema.to_json_schema[:schema][:properties]
      expect(properties[:address]).to include(
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"}
        },
        required: %i[street city],
        additionalProperties: false
      )
    end
  end

  describe "schema definition" do
    let(:schema) { schema_class.new }

    let(:schema_class) do
      UserSchema = Class.new(described_class) do
        string :name, description: "User's name"
        number :age
        boolean :active

        object :address do
          string :street
          string :city
        end

        array :tags, of: :string, description: "User tags"

        array :contacts do
          object do
            string :email
            string :phone
          end
        end

        any_of :status do
          string enum: %w[active pending]
          null
        end

        define :location do
          string :latitude
          string :longitude
        end

        array :locations, of: :location
      end
    end

    let(:json_output) { schema.to_json_schema }

    it "generates the correct JSON schema" do
      # Test name and description
      expect(json_output[:name]).to eq("UserSchema")
      expect(json_output[:description]).to eq(nil)

      properties = json_output[:schema][:properties]

      # Test basic types
      expect(properties[:name]).to eq({type: "string", description: "User's name"})
      expect(properties[:age]).to eq({type: "number"})
      expect(properties[:active]).to eq({type: "boolean"})

      # Test nested object
      expect(properties[:address]).to include(
        type: "object",
        properties: {
          street: {type: "string"},
          city: {type: "string"}
        },
        required: %i[street city],
        additionalProperties: false
      )

      # Test arrays
      expect(properties[:tags]).to eq({
        type: "array",
        description: "User tags",
        items: {type: "string"}
      })

      expect(properties[:contacts]).to include(
        type: "array",
        items: {
          type: "object",
          properties: {
            email: {type: "string"},
            phone: {type: "string"}
          },
          required: %i[email phone],
          additionalProperties: false
        }
      )

      # Test any_of
      expect(properties[:status]).to include(
        anyOf: [
          {type: "string", enum: %w[active pending]},
          {type: "null"}
        ]
      )

      # Test references
      expect(properties[:locations]).to eq({
        type: "array",
        items: {"$ref" => "#/$defs/location"}
      })

      # Test definitions
      expect(json_output[:schema]["$defs"]).to include(
        location: {
          type: "object",
          properties: {
            latitude: {type: "string"},
            longitude: {type: "string"}
          },
          required: %i[latitude longitude]
        }
      )
    end

    it "includes all properties in required array" do
      expect(json_output[:schema][:required]).to contain_exactly(
        :name, :age, :active, :address, :tags, :contacts, :status, :locations
      )
    end

    it "enforces schema constraints" do
      expect(json_output[:schema]).to include(
        additionalProperties: false,
        strict: true
      )
    end

    it "returns JSON string with to_json method" do
      json_string = schema.to_json
      expect(json_string).to be_a(String)

      # Parse the JSON and compare structure (JSON.parse returns string keys)
      parsed_json = JSON.parse(json_string)
      expected_json = JSON.parse(JSON.generate(json_output))
      expect(parsed_json).to eq(expected_json)
    end
  end
end
