# frozen_string_literal: true

module RubyLLM
  class Schema
    class PropertySchemaCollector
      attr_reader :schemas

      def initialize
        @schemas = []
      end

      def collect(&)
        instance_eval(&)
      end

      def string(**options)
        @schemas << Schema.build_property_schema(:string, **options)
      end

      def number(**options)
        @schemas << Schema.build_property_schema(:number, **options)
      end

      def integer(**options)
        @schemas << Schema.build_property_schema(:integer, **options)
      end

      def boolean(**options)
        @schemas << Schema.build_property_schema(:boolean, **options)
      end

      def null(**options)
        @schemas << Schema.build_property_schema(:null, **options)
      end

      def object(...)
        @schemas << Schema.build_property_schema(:object, ...)
      end
    end
  end
end
