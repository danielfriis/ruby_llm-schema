# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module SchemaBuilders
        def string_schema(description: nil, enum: nil, min_length: nil, max_length: nil, pattern: nil, format: nil)
          {
            type: "string",
            enum: enum,
            description: description,
            minLength: min_length,
            maxLength: max_length,
            pattern: pattern,
            format: format
          }.compact
        end

        def number_schema(description: nil, minimum: nil, maximum: nil, multiple_of: nil)
          {
            type: "number",
            description: description,
            minimum: minimum,
            maximum: maximum,
            multipleOf: multiple_of
          }.compact
        end

        def integer_schema(description: nil, minimum: nil, maximum: nil, multiple_of: nil)
          {
            type: "integer",
            description: description,
            minimum: minimum,
            maximum: maximum,
            multipleOf: multiple_of
          }.compact
        end

        def boolean_schema(description: nil)
          {type: "boolean", description: description}.compact
        end

        def null_schema(description: nil)
          {type: "null", description: description}.compact
        end

        def object_schema(description: nil, reference: nil, &block)
          if reference
            reference(reference)
          else
            sub_schema = Class.new(Schema)
            result = sub_schema.class_eval(&block)

            # If the block returned a reference and no properties were added, use the reference
            if result.is_a?(Hash) && result["$ref"] && sub_schema.properties.empty?
              result.merge(description ? {description: description} : {})
            else
              {
                type: "object",
                properties: sub_schema.properties,
                required: sub_schema.required_properties,
                additionalProperties: sub_schema.additional_properties,
                description: description
              }.compact
            end
          end
        end

        def array_schema(description: nil, of: nil, min_items: nil, max_items: nil, &block)
          items = determine_array_items(of, &block)

          {
            type: "array",
            description: description,
            items: items,
            minItems: min_items,
            maxItems: max_items
          }.compact
        end

        def any_of_schema(description: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            anyOf: schemas
          }.compact
        end
      end
    end
  end
end
