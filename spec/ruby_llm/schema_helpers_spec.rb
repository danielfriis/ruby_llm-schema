# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "helpers module approach" do
  include RubyLLM::Helpers

  describe "configuration options" do
    describe "name" do
      it "uses provided name parameter" do
        schema_instance = schema "ProvidedName" do
          string :title
        end

        expect(schema_instance.to_json_schema[:name]).to eq("ProvidedName")
      end

      it "falls back to 'Schema' when not provided" do
        schema_instance = schema do
          string :title
        end

        expect(schema_instance.to_json_schema[:name]).to eq("Schema")
      end
    end

    describe "description" do
      it "uses provided description parameter (takes precedence)" do
        schema_instance = schema "TestSchema", description: "Parameter description" do
          description "Block description" # This gets overridden
          string :title
        end

        expect(schema_instance.to_json_schema[:description]).to eq("Parameter description")
      end

      it "defaults to nil when not provided" do
        schema_instance = schema "TestSchema" do
          string :title
        end

        expect(schema_instance.to_json_schema[:description]).to be_nil
      end
    end

    describe "additional_properties" do
      it "can be set to true within helper block" do
        schema_instance = schema do
          additional_properties true
          string :title
        end

        expect(schema_instance.to_json_schema[:schema][:additionalProperties]).to eq(true)
      end

      it "defaults to false when not provided" do
        schema_instance = schema do
          string :title
        end

        expect(schema_instance.to_json_schema[:schema][:additionalProperties]).to eq(false)
      end
    end

    describe "strict" do
      it "can be set to true within helper block" do
        schema_instance = schema do
          strict true
          string :title
        end

        expect(schema_instance.to_json_schema[:schema][:strict]).to eq(true)
      end

      it "defaults to true when not provided" do
        schema_instance = schema do
          string :title
        end

        expect(schema_instance.to_json_schema[:schema][:strict]).to eq(true)
      end
    end
  end

  describe "comprehensive functionality" do
    it "supports all schema features in helper block" do
      comprehensive_instance = schema "HelperSchema", description: "Comprehensive helper schema" do
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

      json_output = comprehensive_instance.to_json_schema

      expect(json_output[:name]).to eq("HelperSchema")
      expect(json_output[:description]).to eq("Comprehensive helper schema")
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
      configured_instance = schema "HelperConfiguredSchema", description: "Helper test description" do
        additional_properties false
        string :title
      end

      json_output = configured_instance.to_json_schema

      expect(json_output).to include(
        name: "HelperConfiguredSchema",
        description: "Helper test description",
        schema: hash_including(
          type: "object",
          properties: { title: { type: "string" } },
          required: [:title],
          additionalProperties: false,
          strict: true
        )
      )
    end
  end
end 