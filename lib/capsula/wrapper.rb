module Capsula
  class Wrapper

    ##
    # Objects-wrapper which is giving to objects ability to encapsulate other objects
    #

    attr_reader :store
    attr_accessor :item

    def initialize _object_
      @item = _object_
      @store = {}
    end

    # w=Capsula::Wrapper.new(1)
    # => 1
    # w[:a] = 2
    # => 2
    # w
    # => 1
    # w.a
    # => 2
    def []= key, val
      @store[key] = val
    end

    def inspect
      @item.inspect
    end

    def respond_to? name, is_lookup_private = false
      self.store.include?(name) || @item.respond_to?(name, is_lookup_private)
    end

    # TODO:
    # at first - call for wrapper, then for item (if working with hash)
    # []
    # fetch
    # is_a?

    if Object.respond_to?(:try)
      def try *a, &b
        @item.try(*a, &b)
      end
    end

    def method_missing(method, *args, &block)
      if store.has_key?(method)
        store[method]
      else
        @item.send(method, *args, &block)
      end
    end

  end
end
