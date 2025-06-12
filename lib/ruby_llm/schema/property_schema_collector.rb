# frozen_string_literal: true

module RubyLLM
  class Schema
    class PropertySchemaCollector
      attr_reader :schemas

      def initialize
        @schemas = []
      end

      def collect(&block)
        instance_eval(&block)
      end

      def string(**options)
        @schemas << Schema.build_property_schema(:string, **options)
      end

      def number(**options)
        @schemas << Schema.build_property_schema(:number, **options)
      end

      def boolean(**options)
        @schemas << Schema.build_property_schema(:boolean, **options)
      end

      def null(**options)
        @schemas << Schema.build_property_schema(:null, **options)
      end

      def object(**options, &block)
        @schemas << Schema.build_property_schema(:object, **options, &block)
      end
    end
  end
end