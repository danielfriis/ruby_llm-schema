# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "class inheritance approach" do
  describe "configuration options" do
    let(:schema_class) { Class.new(described_class) }

    describe "name" do
      it "uses class name when provided (via constant)" do
        TestNamedSchema = Class.new(described_class)
        instance = TestNamedSchema.new
        expect(instance.to_json_schema[:name]).to eq("TestNamedSchema")
      end

      it "falls back to 'Schema' when not provided (anonymous class)" do
        instance = schema_class.new
        expect(instance.to_json_schema[:name]).to eq("Schema")
      end
    end

    describe "description" do
      it "can be set at class level" do
        schema_class.description("Class-level description")
        expect(schema_class.description).to eq("Class-level description")
      end

      it "applies to the schema properly" do
        schema_class.description("Class-level description")
        instance = schema_class.new
        expect(instance.to_json_schema[:description]).to eq("Class-level description")
      end

      it "defaults to nil when not provided" do
        expect(schema_class.description).to be_nil
      end
    end

    describe "additional_properties" do
      it "can be set to true" do
        schema_class.additional_properties(true)
        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:additionalProperties]).to eq(true)
      end

      it "defaults to false when not provided" do
        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:additionalProperties]).to eq(false)
      end
    end

    describe "strict" do
      it "can be set to true (explicit)" do
        schema_class.strict(true)
        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:strict]).to eq(true)
      end

      it "can be set to false (explicit)" do
        schema_class.strict(false)
        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:strict]).to eq(false)
      end

      it "defaults to true when not provided" do
        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:strict]).to eq(true)
      end
    end
  end

  describe "comprehensive functionality" do
    it "supports all schema features in class definition" do
      comprehensive_class = Class.new(described_class) do
        description "Comprehensive test schema"
        additional_properties true
        strict true

        string :name, description: "Name field"
        integer :count
        boolean :active, required: false

        object :config do
          string :setting
        end

        array :tags, of: :string

        any_of :status do
          string
          null
        end
      end

      instance = comprehensive_class.new("TestSchema")
      json_output = instance.to_json_schema

      expect(json_output[:name]).to eq("TestSchema")
      expect(json_output[:schema][:additionalProperties]).to eq(true)
      expect(json_output[:schema][:strict]).to eq(true)
      expect(json_output[:schema][:properties].keys).to contain_exactly(
        :name, :count, :active, :config, :tags, :status
      )
      expect(json_output[:schema][:required]).to contain_exactly(:name, :count, :config, :tags, :status)
    end
  end

  describe "to_json_schema output" do
    it "produces correctly structured JSON schema" do
      configured_class = Class.new(described_class) do
        description "Test description"
        additional_properties false
        string :title
      end

      instance = configured_class.new("ConfiguredSchema")
      json_output = instance.to_json_schema

      expect(json_output).to include(
        name: "ConfiguredSchema",
        description: "Test description",
        schema: hash_including(
          type: "object",
          properties: {title: {type: "string"}},
          required: [:title],
          additionalProperties: false,
          strict: true
        )
      )
    end

    it "produces correctly structured JSON schema with instance description" do
      configured_class = Class.new(described_class) do
        description "Test description"
        additional_properties false
        string :title
      end

      instance = configured_class.new("ConfiguredSchema", description: "Instance description")
      json_output = instance.to_json_schema

      expect(json_output).to include(
        name: "ConfiguredSchema",
        description: "Instance description"
      )
    end
  end
end
