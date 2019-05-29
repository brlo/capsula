require 'capsula'

RSpec.describe Capsula do
  let(:klass){ Class.new(Capsula::Base) }

  describe 'User can' do
    let(:a) { Struct.new(:b_id) }
    let(:b) { Struct.new(:id) }

    it 'declare new encapsulation plan' do
      klass.plan_for(:b, src_key: :b_id, dst_key: :id, dst_loader: ->(i,o){})
      plans = klass.instance_variable_get('@plans_declarations')
      expect(plans).to have_key(:b)
    end

    it 'preloads objects collection' do
      klass.plan_for(
        :b,
        src_key: :b_id,
        dst_key: :id,
        dst_loader: ->(ids,opt){ ids.map{ |i| b.new(i) } }
      )
      objects = [1,2].map{ |i| a.new(i) }
      objects = klass.new(objects).plans(:b).encapsulate

      expect(objects.first).to respond_to(:b)
      expect(objects.first).to be_a(Capsula::Wrapper)
      expect(objects.first.b.id).to be == objects.first.b_id
    end

    it 'use lambdas in place of symbols for key-declaration' do
      klass.plan_for(
        :b,
        src_key: ->(o){ o.b_id },
        dst_key: ->(o){ o.id },
        dst_loader: ->(ids,opt){ ids.map{ |i| b.new(i) } }
      )

      objects = [1,2].map{ |i| a.new(i) }
      objects = klass.new(objects).plans(:b).encapsulate

      expect(objects.first).to respond_to(:b)
      expect(objects.first).to be_a(Capsula::Wrapper)
      expect(objects.first.b.id).to be == objects.first.b_id
    end

    it 'use default keys-declaration' do
      klass.plan_for(
        :b,
        dst_loader: ->(ids,opt){ ids.map{ |i| b.new(i) } }
      )

      objects = [1,2].map{ |i| a.new(i) }
      objects = klass.new(objects).plans(:b).encapsulate

      expect(objects.first).to respond_to(:b)
      expect(objects.first).to be_a(Capsula::Wrapper)
      expect(objects.first.b.id).to be == objects.first.b_id
    end

    it 'use custom loader' do
      custom_loader = Class.new do
        def initialize items:, opt: {}
          @items = items; @opt = opt; @store = []; @b = Struct.new(:id)
        end

        def collect_ids_and_load_relations
          ids = @items.map{ |i| i.b_id }
          @store = ids.map{ |id| @b.new(id) }
        end

        def get_preloads_for_object o
          @store.find { |a| o.b_id == a.id }
        end
      end

      klass.plan_for(:b, delegate_to: custom_loader)

      objects = [1,2].map{ |i| a.new(i) }
      objects = klass.new(objects).plans(:b).encapsulate

      expect(objects.first).to respond_to(:b)
      expect(objects.first).to be_a(Capsula::Wrapper)
      expect(objects.first.b.id).to be == objects.first.b_id
    end
  end

  describe 'has_many plan' do
    let(:a) { Struct.new(:id) }
    let(:b) { Struct.new(:a_id) }

    it 'working' do
      b_store = [1,2,2,3].map { |a_id| b.new(a_id) }
      klass.plan_for(
        :bs,
        src_key: :id,
        dst_key: [:a_id],
        dst_loader: ->(ids,opt){ b_store.select { |b| ids.include?(b.a_id) } }
      )

      as = [2,3,4].map { |id| a.new(id) }
      as = klass.new(as).plans(:bs).encapsulate

      expect(as[0]).to respond_to(:bs)
      expect(as[0]).to be_a(Capsula::Wrapper)
      expect(as[0].bs.count).to eq(2)
      expect(as[1].bs.count).to eq(1)
      expect(as[2].bs.count).to eq(0)
      expect(as[0].bs[0].a_id).to eq(as[0].id)
      expect(as[1].bs[0].a_id).to eq(as[1].id)
    end
  end

end
