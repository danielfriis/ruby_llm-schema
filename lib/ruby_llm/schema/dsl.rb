# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      # Primitive type methods
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

      # Complex type methods
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

      def any_of(name = nil, required: true, description: nil, &block)
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

      # Schema definition and reference methods
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

      # Schema building methods
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
        when :any_of
          schemas = collect_property_schemas_from_block(&)
          {
            anyOf: schemas
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

      def collect_property_schemas_from_block(&block)
        schemas = []
        schema_builder = self  # Capture the current context that has build_property_schema

        context = Object.new
        context.define_singleton_method(:string) { |name = nil, **options| schemas << schema_builder.build_property_schema(:string, **options) }
        context.define_singleton_method(:number) { |name = nil, **options| schemas << schema_builder.build_property_schema(:number, **options) }
        context.define_singleton_method(:integer) { |name = nil, **options| schemas << schema_builder.build_property_schema(:integer, **options) }
        context.define_singleton_method(:boolean) { |name = nil, **options| schemas << schema_builder.build_property_schema(:boolean, **options) }
        context.define_singleton_method(:null) { |name = nil, **options| schemas << schema_builder.build_property_schema(:null, **options) }
        context.define_singleton_method(:object) { |name = nil, **options, &blk| schemas << schema_builder.build_property_schema(:object, **options, &blk) }
        context.define_singleton_method(:any_of) { |name = nil, **options, &blk| schemas << schema_builder.build_property_schema(:any_of, **options, &blk) }

        context.instance_eval(&block)
        schemas
      end

      def primitive_type?(type)
        type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
      end
    end
  end
end
