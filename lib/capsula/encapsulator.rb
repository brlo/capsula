module Capsula
  class Encapsulator

    ##
    # Main encapsulator functionality
    #

    def initialize items:, declarations:, keys:
      # wrap up not wrapped obects
      @items = wrap_non_wrapped(items)
      @declarations = declarations

      @keys = []
      @keys_values = {}

      ##
      # Parse all declarations by first-level plans.
      #
      # We get a nested plans structure:
      # [
      #   {fruits: [:tree, {bugs: [:locations]]},
      #   :vegetables
      # ]
      # For current objects which we will encapsulate now
      # (call it first-level objects)
      # we need to preload only :fruits and :vegetables,
      # But when the turn comes to encapsulate :fruits,
      # we will transfer plans for :fruits to fruits-encapsulator,
      # and let him deside how to encapsulate tree and bugs into fruits,
      # and then, bugs-encapsulator shoud encapsulate locations and so on.
      #
      keys.each do |i|
        if i.is_a?(Hash)
          k, v = i.first
          @keys << k
          @keys_values[k] = v
        else
          @keys << i
        end
      end

      # for preloaded objects
      @collections = {}
    end

    def preload_and_encapsulate
      if (@keys - @declarations.keys).any?
        raise StandardError.new("unknown relation keys: #{ (@keys - @declarations.keys) }")
      end

      preload

      encapsulate

      @items
    end

    def preload
      @keys.each do |key|
        dec = @declarations[key]
        opt = build_encapsulator_options(key)

        if dec.has_key?(:delegate_to)
          # Delegate to user's encapsulator
          preload_by_delegator(dec[:delegate_to], key, opt)
        else
          # Use native encapsulator
          native_preload(key, dec, opt)
        end
      end
    end

    def encapsulate
      @collections.each do |plan_key, accessories|
        if accessories.has_key?(:delegator)
          # Delegate to user's encapsulator
          encapsulate_by_delegator(
            accessories[:delegator],
            plan_key
          )
        else
          # Use native encapsulator
          native_encapsulation(
            plan_key,
            accessories[:collection],
            accessories[:declaration]
          )
        end
      end
    end

    private

    def preload_by_delegator delegator, key, opt
      d = delegator.new(items: @items, opt: opt)
      d.collect_ids_and_load_relations
      @collections[key] = { delegator: d }
    end

    def native_preload key, dec, opt
      # collect relation ids
      ids = @items.map do |o|
        get_key(o, dec[:src_key])
      end.flatten.uniq.compact

      # preload relations
      @collections[key] = {
        collection: (ids.any? ? dec[:dst_loader].call(ids,opt) : []),
        declaration: dec
      }
    end

    def encapsulate_by_delegator delegator, plan_key
      @items.each do |i|
        val = delegator.get_preloads_for_object(i)
        i[plan_key] = val
      end
    end

    def native_encapsulation plan_key, preloaded_collection, declaration
      col = preloaded_collection
      dec = declaration

      @items.each do |i|
        src_id = get_key(i, dec[:src_key])

        val = if src_id.is_a?(Array)
          # if object has many links to related objects (Array)
          col.select{|c| src_id.include?(c.id) }
        else
          # only one link
          col.find{|c| get_key(c, dec[:dst_key]) == src_id }
        end
        i[plan_key] = val
      end
    end

    def get_key _object_, key_or_lambda
      case key_or_lambda
      when Symbol, String
        _object_.send(key_or_lambda)
      when Proc
        key_or_lambda.call(_object_)
      else
        nil
      end
    end

    def build_encapsulator_options key
      {
        plans: @keys_values[key] || []
      }
    end

    def wrap_non_wrapped items
      items.map do |item|
        if item.class == Wrapper
          item
        else
          Wrapper.new(item)
        end
      end
    end

  end
end
