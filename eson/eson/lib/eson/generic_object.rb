require 'ostruct'

module ESON
  class GenericObject < OpenStruct
    class << self
      alias [] new

      def eson_creatable?
        @eson_creatable
      end

      attr_writer :eson_creatable

      def eson_create(data)
        data = data.dup
        data.delete ESON.create_id
        self[data]
      end

      def from_hash(object)
        case
        when object.respond_to?(:to_hash)
          result = new
          object.to_hash.each do |key, value|
            result[key] = from_hash(value)
          end
          result
        when object.respond_to?(:to_ary)
          object.to_ary.map { |a| from_hash(a) }
        else
          object
        end
      end

      def load(source, proc = nil, opts = {})
        result = ::ESON.load(source, proc, opts.merge(:object_class => self))
        result.nil? ? new : result
      end

      def dump(obj, *args)
        ::ESON.dump(obj, *args)
      end
    end
    self.eson_creatable = false

    def to_hash
      table
    end

    def [](name)
      table[name.to_sym]
    end

    def []=(name, value)
      __send__ "#{name}=", value
    end

    def |(other)
      self.class[other.to_hash.merge(to_hash)]
    end

    def as_eson(*)
      { ESON.create_id => self.class.name }.merge to_hash
    end

    def to_eson(*a)
      as_eson.to_eson(*a)
    end
  end
end
