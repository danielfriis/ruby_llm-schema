# frozen_string_literal: true

module RubyLLM
  class Schema
    module JsonOutput
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
    end
  end
end
