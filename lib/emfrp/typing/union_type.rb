module Emfrp
  module Typing
    class UnionType
      class UnifyError < RuntimeError
        attr_reader :a, :b
        def initialize(a, b)
          @a, @b = a, b
        end
      end
      NameCounter = (0..10000).to_a
      attr_reader :typename, :typeargs, :union
      attr_accessor :name_id, :original_typevar_name

      def self.from_type(type, tbl={})
        case type
        when Emfrp::Type
          case type[:size]
          when nil
            new(type[:name][:desc], type[:args].map{|a| from_type(a, tbl)})
          when SSymbol
            type_size = new(type[:size][:desc].to_i, [])
            new(type[:name][:desc], [type_size] + args.map{|a| from_type(a, tbl)})
          when TypeVar
            args = [type[:size]] + type[:args]
            new(type[:name][:desc], args.map{|a| from_type(a, tbl)})
          end
        when TypeVar
          name = type[:name][:desc]
          if tbl[name]
            tbl[name]
          else
            a = new()
            tbl[name] = a
            a.original_typevar_name = name
            a
          end
        when UnionType
          type
        else
          raise "error"
        end
      end

      def initialize(*args)
        if args.length == 2
          @typename = args[0]
          @typeargs = args[1]
        elsif args.length == 0
          @union = [self]
          @name_id = NameCounter.shift
        else
          raise "Wrong number of arguments (#{args.length} for 0, 2)"
        end
      end

      def var?
        @union
      end

      def include?(other)
        unless other.var?
          raise "argument error for UnionType#include?"
        end
        if self.var?
          self.name_id == other.name_id
        else
          self.typeargs.any?{|t| t.include?(other)}
        end
      end

      def unite(other)
        @union = (self.union + other.union).uniq
        substitute_id = @union.map{|t| t.name_id}.min
        @union.each{|t| t.name_id = substitute_id}
      end

      def typevars
        if var?
          self
        else
          typeargs.map{|t| t.typevars}.flatten
        end
      end

      def transform(other)
        @typename = other.typename
        @typeargs = other.typeargs
        @union = nil
      end

      def copy(tbl={})
        if self.var?
          if tbl[self]
            tbl[self]
          else
            alt = self.class.new
            self.union.each{|t| tbl[t] = alt}
            alt
          end
        else
          self.class.new(self.typename, self.typeargs.map{|t| t.copy(tbl)})
        end
      end

      def unify(other)
        if !self.var? && !other.var?
          if self.typename == other.typename && self.typeargs.size == other.typeargs.size
            self.typeargs.zip(other.typeargs).each{|t1, t2| t1.unify(t2)}
          else
            raise UnifyError.new(nil, nil)
          end
        elsif !self.var? && other.var?
          other.union.each do |t|
            self.occur_check(t)
            t.transform(self)
          end
        elsif self.var? && !other.var?
          self.union.each do |t|
            other.occur_check(t)
            t.transform(other)
          end
        else
          self.unite(other)
          other.unite(self)
        end
      rescue UnifyError => err
        raise UnifyError.new(self, other)
      end

      def occur_check(var)
        if !self.var?
          self.typeargs.each{|t| t.occur_check(var)}
        end
        if self == var
          raise UnifyError.new(nil, nil)
        end
      end

      def inspect
        if self.var?
          "a#{self.name_id}" + (@original_typevar_name ? "(#{@original_typevar_name})" : "")
        else
          "#{self.typename}[#{self.typeargs.map{|t| t.inspect}.join(", ")}]"
        end
      end
    end
  end
end
