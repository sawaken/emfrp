module Emfrp
  module Typing
    class UnionType
      UnifyError = Class.new(RuntimeError)
      NameCounter = (0..100).to_a
      attr_reader :typename, :typeargs, :union
      attr_accessor :name_id

      def self.from_type(type, tbl={})
        case type
        when Emfrp::Type
          new(type[:name][:desc], type[:args].map{|a| from_type(a, tbl)})
        when Emfrp::TypeVar
          name = type[:name][:desc]
          if tbl[name]
            tbl[name]
          else
            a = new()
            tbl[name] = a
            a
          end
        end
      end

      def initialize(*args)
        if args.length == 2
          @typename = args[0]
          @typeargs = args[1]
        else
          @union = [self]
          @name_id = NameCounter.shift
        end
      end

      def var?
        @union
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
            raise UnifyError.new
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
      end

      def occur_check(var)
        if !self.var?
          self.typeargs.each{|t| t.occur_check(var)}
        end
        if self == var
          raise UnifyError.new
        end
      end

      def inspect
        if self.var?
          "a#{self.name_id}"
        else
          "#{self.typename}[#{self.typeargs.map{|t| t.inspect}.join(", ")}]"
        end
      end
    end
  end
end
