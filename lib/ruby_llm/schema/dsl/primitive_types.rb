# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module PrimitiveTypes
        def string(name, required: true, **options)
          add_property(name, string_schema(**options), required: required)
        end

        def number(name, required: true, **options)
          add_property(name, number_schema(**options), required: required)
        end

        def integer(name, required: true, **options)
          add_property(name, integer_schema(**options), required: required)
        end

        def boolean(name, required: true, **options)
          add_property(name, boolean_schema(**options), required: required)
        end

        def null(name, required: true, **options)
          add_property(name, null_schema(**options), required: required)
        end
      end
    end
  end
end
