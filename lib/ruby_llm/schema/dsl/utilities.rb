# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module Utilities
        # Schema definition and reference methods
        def define(name, &)
          sub_schema = Class.new(Schema)
          sub_schema.class_eval(&)

          definitions[name] = {
            type: "object",
            properties: sub_schema.properties,
            required: sub_schema.required_properties,
            additionalProperties: sub_schema.additional_properties
          }
        end

        def reference(schema_name)
          if schema_name == :root
            {"$ref" => "#"}
          else
            {"$ref" => "#/$defs/#{schema_name}"}
          end
        end

        private

        def add_property(name, definition, required:)
          properties[name.to_sym] = definition
          required_properties << name.to_sym if required
        end

        def determine_array_items(of, &)
          return collect_schemas_from_block(&).first if block_given?
          return send("#{of}_schema") if primitive_type?(of)
          return reference(of) if of.is_a?(Symbol)
          return schema_class_to_inline_schema(of) if schema_class?(of)

          raise InvalidArrayTypeError, "Invalid array type: #{of.inspect}. Must be a primitive type (:string, :number, etc.), a symbol reference, or a Schema class."
        end

        def determine_object_reference(of, description = nil)
          result = case of
          when Symbol
            reference(of)
          when Class
            if schema_class?(of)
              schema_class_to_inline_schema(of)
            else
              raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Class must inherit from RubyLLM::Schema."
            end
          else
            raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Must be a symbol reference or a Schema class."
          end

          description ? result.merge(description: description) : result
        end

        def collect_schemas_from_block(&block)
          schemas = []
          schema_builder = self

          context = Object.new

          # Dynamically create methods for all schema builders
          schema_builder.methods.grep(/_schema$/).each do |schema_method|
            type_name = schema_method.to_s.sub(/_schema$/, "")

            context.define_singleton_method(type_name) do |name = nil, **options, &blk|
              schemas << schema_builder.send(schema_method, **options, &blk)
            end
          end

          # Allow Schema classes to be accessed in the context
          context.define_singleton_method(:const_missing) do |name|
            const_get(name) if const_defined?(name)
          end

          context.instance_eval(&block)
          schemas
        end

        def primitive_type?(type)
          type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
        end

        def schema_class?(type)
          type.is_a?(Class) && type < Schema
        end

        def schema_class_to_inline_schema(schema_class)
          # Directly convert schema class to inline object schema
          {
            type: "object",
            properties: schema_class.properties,
            required: schema_class.required_properties,
            additionalProperties: schema_class.additional_properties
          }.tap do |schema|
            schema[:description] = schema_class.description if schema_class.description
          end
        end
      end
    end
  end
end
