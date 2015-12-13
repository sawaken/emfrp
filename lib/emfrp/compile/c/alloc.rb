module Emfrp
  class AllocRequrement
    def initialize(top)
      @top = top
      @alloc_table = AllocTable.new(top)
    end

    def requirement
      sorted_datas = nil
      sorted_nodes = nil
      init_nodes = sorted_nodes.select{|n| n[:init_exp]
      max_amount = Alloc.empty
      max_amount = data_requirement(sorted_datas, max_amount)
      max_amount = node_init_requirement(init_nodes, max_amount, sorted_datas)
      max_amount = node_loop_requirement(sorted_nodes, max_amount, init_nodes, sorted_datas)
      return max_amount
    end

    def data_requirement(sorted_datas, max_amount)
      retains = []
      sorted_datas.each do |d|
        max_amount |= type_alloc_sum(retains) & exp_alloc(d[:exp])
      end
      return max_amount
    end

    def node_init_requirement(init_nodes, max_amount, datas)
      retains = datas.clone
      init_nodes.each do |n|
        max_amount |= type_alloc_sum(retains) & exp_alloc(n[:init_exp])
        retains << n
      end
      return max_amount
    end

    def node_loop_requirement(sorted_nodes, max_amount, init_nodes, datas)
      lrefs = init_nodes
      crefs = []
      sorted_nodes.each_with_index do |n, i|
        max_amount |= type_alloc_sum(datas + lrefs + crefs) & exp_alloc(n[:exp])
        crefs << n
        lrefs.reject! do |x|
          i + 1 >= ref_pos_last(sorted_nodes, x)
        end
        crefs.reject! do |x|
          i + 1 >= ref_pos_current(sorted_nodes, x)
        end
      end
      return max_amount
    end

    def ref_pos_last(sorted_nodes, node)

    end

    def ref_pos_current(sorted_nodes, node)

    end

    def type_alloc_sum(defs)
      defs.inject(Alloc.empty) do |acc, d|
        t = @top[:dict][:itype_space][d[:typing].to_uniq_str].get
        acc & @alloc_table.type_alloc(t)
      end
    end

    def exp_alloc(exp)
      @alloc_table.exp_alloc(exp)
    end
  end

  class AllocTable
    def initialize(top)
      @top = top
      @tbl = {}
      @type_tbl = {}
    end

    def type_alloc(type_def)
      return @type_tbl[type_def] if @type_tbl[type_def]
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
end
