# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "factory method (.create) approach" do
  describe "configuration options" do
    describe "name" do
      it "uses class name when provided (via constant assignment)" do
        stub_const("NamedFactorySchema", described_class.create do
          string :title
        end)

        instance = NamedFactorySchema.new
        expect(instance.to_json_schema[:name]).to eq("NamedFactorySchema")
      end

      it "falls back to 'Schema' when not provided (anonymous class)" do
        schema_class = described_class.create do
          string :title
        end

        instance = schema_class.new
        expect(instance.to_json_schema[:name]).to eq("Schema")
      end
    end

    describe "description" do
      it "can be set within factory block" do
        schema_class = described_class.create do
          description "Factory description"
          string :title
        end

        expect(schema_class.description).to eq("Factory description")
      end

      it "defaults to nil when not provided" do
        schema_class = described_class.create do
          string :title
        end

        expect(schema_class.description).to be_nil
      end
    end

    describe "additional_properties" do
      it "can be set to true within factory block" do
        schema_class = described_class.create do
          additional_properties true
          string :title
        end

        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:additionalProperties]).to eq(true)
      end

      it "defaults to false when not provided" do
        schema_class = described_class.create do
          string :title
        end

        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:additionalProperties]).to eq(false)
      end
    end

    describe "strict" do
      it "can be set to true within factory block" do
        schema_class = described_class.create do
          strict true
          string :title
        end

        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:strict]).to eq(true)
      end

      it "defaults to true when not provided" do
        schema_class = described_class.create do
          string :title
        end

        instance = schema_class.new
        expect(instance.to_json_schema[:schema][:strict]).to eq(true)
      end
    end
  end

  describe "comprehensive functionality" do
    it "supports all schema features in factory block" do
      comprehensive_class = described_class.create do
        description "Comprehensive factory schema"
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

      instance = comprehensive_class.new("FactorySchema")
      json_output = instance.to_json_schema

      expect(json_output[:name]).to eq("FactorySchema")
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
      configured_class = described_class.create do
        description "Factory test description"
        additional_properties false
        string :title
      end

      instance = configured_class.new("FactoryConfiguredSchema")
      json_output = instance.to_json_schema

      expect(json_output).to include(
        name: "FactoryConfiguredSchema",
        description: "Factory test description",
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
      configured_class = described_class.create do
        description "Factory test description"
        additional_properties false
        string :title
      end

      instance = configured_class.new("FactoryConfiguredSchema", description: "Instance description")
      json_output = instance.to_json_schema

      expect(json_output).to include(
        name: "FactoryConfiguredSchema",
        description: "Instance description"
      )
    end
  end
end
