module Rubord
  class Collection
    include Enumerable

    def initialize
      @store = {}
    end

    def [](key)
      @store[key]
    end

    def []=(key, value)
      @store[key] = value
    end

    def get(key)
      @store[key]
    end

    def set(key, value)
      @store[key] = value
      self
    end

    def delete(key)
      @store.delete(key)
    end

    def each(&block)
      @store.each_value(&block)
    end

    def map(&block)
      @store.values.map(&block)
    end

    def filter(&block)
      self.class.new.tap do |col|
        @store.each do |k, v|
          col.set(k, v) if block.call(v)
        end
      end
    end

    def find(&block)
      @store.values.find(&block)
    end

    def values
      @store.values
    end

    def keys
      @store.keys
    end

    def size
      @store.size
    end

    def empty?
      @store.empty?
    end

    def to_h
      @store.dup
    end
  end
end