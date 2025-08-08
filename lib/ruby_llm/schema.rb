# frozen_string_literal: true

require_relative "schema/version"
require_relative "schema/property_schema_collector"
require_relative "schema/errors"
require_relative "schema/helpers"
require_relative "schema/validator"
require "json"
require "set"

module RubyLLM
  class Schema
    PRIMITIVE_TYPES = %i[string number integer boolean null].freeze

    class << self
      def create(&block)
        schema_class = Class.new(Schema)
        schema_class.class_eval(&block)
        schema_class
      end

      def description(description = nil)
        @description = description if description
        @description
      end

      def additional_properties(value = nil)
        return @additional_properties ||= false if value.nil?
        @additional_properties = value
      end

      def strict(value = nil)
        if value.nil?
          return @strict.nil? ? (@strict = true) : @strict
        end
        @strict = value
      end

      def string(name = nil, enum: nil, description: nil, required: true, min_length: nil, max_length: nil, pattern: nil, format: nil)
        options = {
          enum: enum,
          description: description,
          minLength: min_length,
          maxLength: max_length,
          pattern: pattern,
          format: format
        }.compact
        
        add_property(name, build_property_schema(:string, **options), required: required)
      end

      def number(name = nil, description: nil, required: true, minimum: nil, maximum: nil, multiple_of: nil)
        options = {
          description: description,
          minimum: minimum,
          maximum: maximum,
          multipleOf: multiple_of
        }.compact
        
        add_property(name, build_property_schema(:number, **options), required: required)
      end

      def integer(name = nil, description: nil, required: true)
        add_property(name, build_property_schema(:integer, description: description), required: required)
      end

      def boolean(name = nil, description: nil, required: true)
        add_property(name, build_property_schema(:boolean, description: description), required: required)
      end

      def null(name = nil, description: nil, required: true)
        add_property(name, build_property_schema(:null, description: description), required: required)
      end

      def object(name = nil, description: nil, required: true, &block)
        add_property(name, build_property_schema(:object, description: description, &block), required: required)
      end

      def array(name, of: nil, description: nil, required: true, min_items: nil, max_items: nil, &block)
        items = determine_array_items(of, &block)

        add_property(name, {
          type: "array",
          description: description,
          items: items,
          minItems: min_items,
          maxItems: max_items
        }.compact, required: required)
      end

      def any_of(name, required: true, description: nil, &block)
        schemas = collect_property_schemas_from_block(&block)

        add_property(name, {
          description: description,
          anyOf: schemas
        }.compact, required: required)
      end

      def optional(name, description: nil, &block)
        any_of(name, description: description) do
          instance_eval(&block)
          null
        end
      end

      def define(name, &)
        sub_schema = Class.new(Schema)
        sub_schema.class_eval(&)

        definitions[name] = {
          type: "object",
          properties: sub_schema.properties,
          required: sub_schema.required_properties
        }
      end

      def reference(schema_name)
        {"$ref" => "#/$defs/#{schema_name}"}
      end

      def properties
        @properties ||= {}
      end

      def required_properties
        @required_properties ||= []
      end

      def definitions
        @definitions ||= {}
      end

      def build_property_schema(type, **options, &)
        case type
        when :string
          {
            type: "string",
            enum: options[:enum],
            description: options[:description],
            minLength: options[:minLength],
            maxLength: options[:maxLength],
            pattern: options[:pattern],
            format: options[:format]
          }.compact
        when :number
          {
            type: "number",
            description: options[:description],
            minimum: options[:minimum],
            maximum: options[:maximum],
            multipleOf: options[:multipleOf]
          }.compact
        when :integer
          {
            type: "integer",
            description: options[:description],
            minimum: options[:minimum],
            maximum: options[:maximum],
            multipleOf: options[:multipleOf]
          }.compact
        when :boolean
          {type: "boolean", description: options[:description]}.compact
        when :null
          {type: "null", description: options[:description]}.compact
        when :object
          sub_schema = Class.new(Schema)
          sub_schema.class_eval(&)

          {
            type: "object",
            properties: sub_schema.properties,
            required: sub_schema.required_properties,
            additionalProperties: additional_properties,
            description: options[:description]
          }.compact
        else
          raise InvalidSchemaTypeError, type
        end
      end

      def validate!
        validator = Validator.new(self)
        validator.validate!
      end

      def valid?
        validator = Validator.new(self)
        validator.valid?
      end

      private

      def add_property(name, definition, required:)
        properties[name.to_sym] = definition
        required_properties << name.to_sym if required
      end

      def determine_array_items(of, &)
        return collect_property_schemas_from_block(&).first if block_given?
        return build_property_schema(of) if primitive_type?(of)
        return reference(of) if of.is_a?(Symbol)

        raise InvalidArrayTypeError, of
      end

      def collect_property_schemas_from_block(&)
        collector = PropertySchemaCollector.new
        collector.collect(&)
        collector.schemas
      end

      def primitive_type?(type)
        type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
      end
    end

    def initialize(name = nil, description: nil)
      @name = name || self.class.name || "Schema"
      @description = description
    end

    def to_json_schema
      validate!  # Validate schema before generating JSON
      
      {
        name: @name,
        description: @description || self.class.description,
        schema: {
          :type => "object",
          :properties => self.class.properties,
          :required => self.class.required_properties,
          :additionalProperties => self.class.additional_properties,
          :strict => self.class.strict,
          "$defs" => self.class.definitions
        }
      }
    end

    def to_json(*_args)
      validate!  # Validate schema before generating JSON string
      JSON.pretty_generate(to_json_schema)
    end

    def validate!
      self.class.validate!
    end

    def valid?
      self.class.valid?
    end

    def method_missing(method_name, ...)
      if respond_to_missing?(method_name)
        send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      %i[string number integer boolean array object any_of null].include?(method_name) || super
    end
  end
end
