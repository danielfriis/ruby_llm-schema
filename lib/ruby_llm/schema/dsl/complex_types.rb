# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module ComplexTypes
        def object(name, required: true, **options, &block)
          add_property(name, object_schema(**options, &block), required: required)
        end

        def array(name, required: true, **options, &block)
          add_property(name, array_schema(**options, &block), required: required)
        end

        def any_of(name, required: true, **options, &block)
          add_property(name, any_of_schema(**options, &block), required: required)
        end

        def optional(name, **options, &block)
          any_of(name, **options) do
            instance_eval(&block)
            null
          end
        end
      end
    end
  end
end
