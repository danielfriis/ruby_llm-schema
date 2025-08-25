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

          raise InvalidArrayTypeError, of
        end

        def collect_schemas_from_block(&block)
          schemas = []
          schema_builder = self

          context = Object.new
          
          # Dynamically create methods for all schema builders
          schema_builder.methods.grep(/_schema$/).each do |schema_method|
            type_name = schema_method.to_s.sub(/_schema$/, '')
            
            context.define_singleton_method(type_name) do |name = nil, **options, &blk|
              schemas << schema_builder.send(schema_method, **options, &blk)
            end
          end

          context.instance_eval(&block)
          schemas
        end

        def primitive_type?(type)
          type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
        end
      end
    end
  end
end
