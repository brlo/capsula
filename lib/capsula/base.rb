module Capsula
  class Base

    ##
    # Base class for inheritence when creating new Encapsulators
    #

    def initialize items
      @items = items
    end

    def plans *keys
      @keys = keys.flatten.compact.uniq
      self
    end

    def encapsulate
      Encapsulator.new(
        items: @items,
        declarations: self.class.merged_plans_declarations,
        keys: @keys
      ).preload_and_encapsulate
    end

    class << self

      # DSL method
      def plan_for relation_key, **opt
        add_to_plans_declaration relation_key: relation_key, **opt
      end

      # declarations from current class and from all parents, if such present
      def merged_plans_declarations
        return @merged_plans_declarations if defined?(@merged_plans_declarations)
        @merged_plans_declarations = plans_declarations || {}

        sc = self
        while (sc = sc.superclass).respond_to?(:plans_declarations)
          @merged_plans_declarations.merge!(sc.plans_declarations)
        end
        @merged_plans_declarations
      end

      private

      # declaration only for current class
      def plans_declarations
        @plans_declarations
      end

      def add_to_plans_declaration relation_key:, **opt
        @plans_declarations ||= {}
        opt[:dst_key] = :id unless opt.has_key?(:dst_key)
        opt[:src_key] = :"#{relation_key}_id" unless opt.has_key?(:src_key)

        @plans_declarations[relation_key] = opt
      end

    end

  end
end
