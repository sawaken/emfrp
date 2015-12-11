module Emfrp
  class AllocTable
    class Alloc
      attr_reader :hash
      def initialize(hash)
        @hash = hash
      end

      def self.empty
        self.new({})
      end

      def self.one(k)
        self.new(k => 1)
      end

      def |(other)
        Alloc.new self.hash.merge(other.hash){|k, v1, v2| [v1, v2].max}
      end

      def &(other)
        Alloc.new self.hash.merge(other.hash){|k, v1, v2| v1 + v2}
      end
    end

    def initialize(top)
      @top = top
      @tbl = {}
      @type_tbl = {}
    end

    def type_alloc(type_def)
      @type_tbl[type_def] if @type_tbl[type_def]
      case type_def
      when TypeDef
        tvalue_type_max_allocs = type_def[:tvalues].map do |tval|
          param_type_max_allocs = tval[:params].map do |param|
            type_alloc(@top[:dict][:itype_space][param[:typing].to_uniq_str].get)
          end
          param_type_max_allocs.inject(Alloc.empty, &:&)
        end
        self_type_alloc = type_def[:static] ? Alloc.one(type_def) : Alloc.empty
        @type_tbl[type_def] = tvalue_type_max_allocs.inject(&:|) & self_type_alloc
      when PrimTypeDef
        @type_tbl[type_def] = Alloc.empty
      end
    end

    def exp_alloc(exp)
      return @tbl[exp] if @tbl[exp]
      case exp
      when MatchExp
        @tbl[exp] = exp[:cases].map{|c| exp_alloc(c[:exp])}.inject(&:|)
      when FuncCall
        args_alloc = exp[:args].map{|x| exp_alloc(x)}.inject(&:&)
        key = ([exp] + exp[:args]).map{|x| x[:typing].to_uniq_str} + [exp[:name][:desc]]
        raise "Assertion error" unless @top[:dict][:ifunc_space][key]
        f = @top[:dict][:ifunc_space][key].get
        if f.is_a?(FuncDef)
          @tbl[exp] = args_alloc & exp_alloc(f[:exp])
        else
          @tbl[exp] = args_alloc
        end
      when ValueConst
        key = exp[:typing].to_uniq_str
        raise "Assertion error" unless @top[:dict][:itype_space][key]
        type_def = @top[:dict][:itype_space][key].get
        @tbl[exp] = exp[:cases].map{|c| exp_alloc(c[:exp])}.inject(&:|) & Alloc.one(type_def)
      when Syntax
        @tbl[exp] = Alloc.empty
      else
        raise "Assertion error"
      end
    end
  end
end
