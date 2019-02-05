# Capsula
The tool for encapsulating (preloading, including) related objects into **any** object.

## How to use:

Add to Gemfile:

```
gem 'capsula'
```

Then:

```ruby
starships = <get_your_space_fleet>

starships = StarshipsEncapsulator.new(starships).plans(
  :fuel, :oxygen, :food, { spaceman: [:space_suit] }
).encapsulate

# Now let's get a suit for our spaceman:
starships.first&.spaceman&.space_suit
=> <awesome space suit>
# no actual action was triggered,
# immediate result was received from Capsula's wrapper
```

Let's see how `StarshipsEncapsulator` looks:

```ruby
class StarshipsEncapsulator < Capsula::Base
  plan_for :fuel,
    src_key: :fuel_id,
    dst_key: :id,
    dst_loader: ->(ids,opt){ MyFuelStation.find_fuel_by_ids(ids) }
    # Example loader for ActiveRecord model Fuel:
    # dst_loader: ->(ids,opt){ Fuel.where(id: ids).includes(opt[:plans]).to_a }

  # Plans for other relations...
end
```

### src_key, dst_key

**default values:**

Definition for `src_key` and `dst_key` can be skipped if they values are `:fuel_id` (`<key_name>_id`) and `:id`

**lambdas:**

For key-definition can be used lambdas:

```ruby
src_key: ->(o){ o.some_hash_data.fetch(:fuel_id, 'A-95') }
dst_key: ->(o){ o.extract_fuel_id_from_octane_number }
```

### dst_loader

**nested plans:**

`dst_loader` receive plans in `opt[:plans]` only for related class.

So, if user request plans for `:fuel, :oxygen, :food, { spaceman: [:space_suit] }`,
then `SpacemanEncapsulator` receive `[:space_suit]` plans in `opt[:plans]` and so on.

## How it works:

All objects is wrapping into special transparent wrapper which
translate all methods to wrapped object, except methods-names which was used for encapsulating before:

```ruby
starships = StarshipsEncapsulator.new(starships).plans(:fuel, :oxygen).encapsulate
starships.first.oxygen
=> <oxygen> # instant response, because already present in Capsula
```

Rest methods transparently sending to wrapped object:

```ruby
starships.first.food
=> <pizza> # returns to Mothership and cook pizza
```

## Custom encapsulators (dst_loaders):
For difficult preloading logic can be used custom loader:

```ruby
class CustomLoader
  def initialize items:, opt: {}
    @items = items; @opt = opt; @store = [];
  end

  # This method is triggered by Capsula
  def collect_ids_and_load_relations
    ids = @items.map{ |i| i.fuel_id }
    @store = Fuel.where(id: ids).to_a
  end

  # This method is calling by Capsula during encapsulation
  def get_preloads_for_object starship
    @store.find { |fuel| starship.fuel_id == fuel.id }
  end
end


class StarshipsEncapsulator < Capsula::Base
  plan_for :fuel, delegate_to: CustomLoader
end
```

## Contributing

* Fork the project.
* Run `bundle install`
* Run `bundle exec guard`
* Make your feature addition or bug fix.
* Add tests for it. This is important.
* Send me a pull request.
