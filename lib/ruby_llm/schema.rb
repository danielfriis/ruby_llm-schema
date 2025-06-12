# frozen_string_literal: true

require_relative "schema/version"
require_relative "schema/property_schema_collector"
require_relative "schema/errors"
require_relative "schema/helpers"
require "json"

module RubyLLM
  class Schema
    PRIMITIVE_TYPES = %i[string number boolean null].freeze

    class << self
      def create(&block)
        schema_class = Class.new(Schema)
        schema_class.class_eval(&block)
        schema_class
      end

      def string(name = nil, enum: nil, description: nil, required: true)
        add_property(name, build_property_schema(:string, enum: enum, description: description), required: required)
      end

      def number(name = nil, description: nil, required: true)
        add_property(name, build_property_schema(:number, description: description), required: required)
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

      def array(name, of: nil, description: nil, required: true, &block)
        items = determine_array_items(of, &block)

        add_property(name, {
          type: "array",
          description: description,
          items: items
        }.compact, required: required)
      end

      def any_of(name, required: true, description: nil, &block)
        schemas = collect_property_schemas_from_block(&block)

        add_property(name, {
          description: description,
          anyOf: schemas
        }.compact, required: required)
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
          {type: "string", enum: options[:enum], description: options[:description]}.compact
        when :number
          {type: "number", description: options[:description]}.compact
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
            additionalProperties: false,
            description: options[:description]
          }.compact
        else
          raise InvalidSchemaTypeError, type
        end
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

    def initialize(name = nil, description = nil)
      @name = name || self.class.name
      @description = description
    end

    def to_json_schema
      {
        name: @name,
        description: @description,
        schema: {
          :type => "object",
          :properties => self.class.properties,
          :required => self.class.required_properties,
          :additionalProperties => false,
          :strict => true,
          "$defs" => self.class.definitions
        }
      }
    end

    def to_json(*_args)
      JSON.pretty_generate(to_json_schema)
    end

    def method_missing(method_name, ...)
      if respond_to_missing?(method_name)
        send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      %i[string number boolean array object any_of null].include?(method_name) || super
    end
  end
end
