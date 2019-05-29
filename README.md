# Capsula
The tool for preloading related objects into **any** object to prevent N+1 queries.

## INSTALL

```
gem 'capsula'
```

## USE

```ruby
require 'capsula'

# our objects
$cars = [ {name: 'A', brand_id: 3}, {name: 'B', brand_id: 1}, {name: 'C', brand_id: 1} ]
$brands = [ {id: 1, name: 'Ferrari'}, {id: 2, name: 'Lamborghini'}, {id: 3, name: 'Rolls-Royce'} ]

# let's preload cars with brands

# our capsula-preloader
class CarPreloader < Capsula::Base
  plan_for :brand,
    src_key: -> (car) { car[:brand_id] },
    dst_key: -> (brand) { brand[:id] },
    dst_loader: -> (ids, opt) { $brands.select { |b| ids.include?(b[:id]) } }
end

# ok, preload!
$cars = CarPreloader.new($cars).plans(:brand).encapsulate

$cars
# => [{:name=>"A", :brand_id=>3}, {:name=>"B", :brand_id=>1}, {:name=>"C", :brand_id=>1}]

# hm... where is brands?

$cars.first.brand
# => {:id=>3, :name=>"Rolls-Royce"}

$cars[0].brand
# => {:id=>3, :name=>"Rolls-Royce"}
$cars[1].brand
# => {:id=>1, :name=>"Ferrari"}
$cars[2].brand
# => {:id=>1, :name=>"Ferrari"}

# so, source objects leave untouched, but was wrapped for methods interception
```

### ActiveRecord case:

```ruby
cars = Cars.where(id: [1,2,3]).to_a

cars = CarPreloader.new(cars).plans(
  :fuel, :food, { driver: [:car_keys, :sunglasses] }
).encapsulate

cars.first.driver.car_keys
=> <car_keys>
# no actual action (any SQL query) was triggered,
# immediate result was received from Capsula's wrapper
```

Let's see how `CarPreloader` looks:

```ruby
class StarshipsEncapsulator < Capsula::Base
  plan_for :driver,
    src_key: :driver_id, # it's default value, so can be skipped
    dst_key: :id,        # it's default value, so can be skipped
    # Example loader for ActiveRecord model Driver:
    dst_loader: -> (ids, opt) {
        Driver.where(id: ids).includes(opt[:plans]).to_a
      }

  # # Plans for other relations:
  # plan_for :fuel, ...
  # plan_for :food, ...
end
```

### has_many example

You can use custom encapsulator, but stantard encapsulator understand you if dst_key be placed inside array:

```ruby
class Sea < Capsula::Base
  plan_for :crabs,
    src_key: :name,
    dst_key: [:sea_name], # key inside array signals about has_many relation
    dst_loader: -> (sea_names, opt) {
        Crab.where(sea_name: sea_names).includes(opt[:plans]).to_a
      }
end
```

### src_key, dst_key

**default values:**

Definition for `src_key` and `dst_key` can be skipped if they values are `:driver_id` (`<key_name>_id`) and `:id`

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
    preloads = Fuel.where(id: ids).to_a
    @store = preloads.index_by(&:id)
  end

  # This method is calling by Capsula during encapsulation
  def get_preloads_for_object starship
    @store[starship.fuel_id]
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
