module Emfrp
  class AllocRequirement
    def initialize(top)
      @top = top
      @alloc_table = AllocTable.new(top)
      @sorted_nodes = @top[:dict][:sorted_nodes].map{|x| x.get}
    end

    def requirement
      sorted_datas = @top[:dict][:sorted_datas].map{|x| x.get}
      init_nodes = @sorted_nodes.select{|n| n[:init_exp]}
      max_amount = Alloc.empty
      max_amount = data_requirement(sorted_datas, max_amount)
      max_amount = node_init_requirement(init_nodes, max_amount, sorted_datas)
      max_amount = node_loop_requirement(max_amount, init_nodes, sorted_datas)
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

    def node_loop_requirement(max_amount, init_nodes, datas)
      lrefs = init_nodes
      crefs = []
      @sorted_nodes.each_with_index do |n, i|
        max_amount |= type_alloc_sum(datas + lrefs + crefs) & exp_alloc(n[:exp])
        crefs << n
        lrefs.reject! do |x|
          i >= ref_pos_last(x)
        end
        crefs.reject! do |x|
          i >= ref_pos_current(x)
        end
      end
      return max_amount
    end

    def ref_pos_last(node)
      res = -1
      @sorted_nodes.each_with_index do |n, i|
        if n[:params].any?{|param| param[:last] && param[:name] == node[:name]}
          res = i
        end
      end
      return res
    end

    def ref_pos_current(node)
      res = -1
      @sorted_nodes.each_with_index do |n, i|
        if n[:params].any?{|param| !param[:last] && param[:name] == node[:name]}
          res = i
        end
      end
      return res
    end

    def life_point(node)
      self_position = @sorted_nodes.index{|x| x == node}
      distance_to_end = @sorted_nodes.size - self_position
      res = []
      @sorted_nodes.each_with_index do |x, i|
        x[:params].each do |param|
          if param[:name] == node[:name]
            if param[:last]
              res << distance_to_end + i
            else
              res << i - self_position
            end
          end
        end
      end
      if res == []
        raise "Assertion error"
      else
        return res.max
      end
    end

    def type_alloc_sum(defs)
      defs.inject(Alloc.empty) do |acc, d|
        type_def = @alloc_table.utype_to_type_def(d[:typing])
        acc & @alloc_table.type_alloc(type_def)
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

    def utype_to_type_def(utype)
      if t = @top[:dict][:itype_space][utype.to_uniq_str]
        t.get
      elsif t = @top[:dict][:type_space][utype.typename]
        t.get
      else
        raise "Assertion error"
      end
    end

    def type_alloc(type_def)
      return @type_tbl[type_def] if @type_tbl[type_def]
      case type_def
      when TypeDef
        tvalue_type_max_allocs = type_def[:tvalues].map do |tval|
          param_type_max_allocs = tval[:params].map do |param|
            type_alloc(utype_to_type_def(param[:typing]))
          end
          param_type_max_allocs.inject(Alloc.empty, &:&)
        end
        self_type_alloc = type_def[:static] ? Alloc.empty : Alloc.one(Link.new(type_def))
        @type_tbl[type_def] = tvalue_type_max_allocs.inject(&:|) & self_type_alloc
      when PrimTypeDef
        @type_tbl[type_def] = Alloc.empty
      end
    end

    def exp_alloc(exp)
      return @tbl[exp] if @tbl[exp]
      case exp
      when MatchExp
        @tbl[exp] = exp[:cases].map{|c| exp_alloc(c[:exp])}.inject(&:|) & exp_alloc(exp[:exp])
      when FuncCall
        args_alloc = exp[:args].map{|x| exp_alloc(x)}.inject(&:&)
        key = ([exp] + exp[:args]).map{|x| x[:typing].to_uniq_str} + [exp[:name][:desc]]
        if @top[:dict][:ifunc_space][key]
          f = @top[:dict][:ifunc_space][key].get
          @tbl[exp] = args_alloc & exp_alloc(f[:exp])
        elsif f = @top[:dict][:func_space][exp[:name][:desc]]
          if f.get.is_a?(PrimFuncDef)
            @tbl[exp] = args_alloc
          else
            raise "Assertion error"
          end
        else
          raise "Assertion error"
        end
      when ValueConst
        args_alloc = exp[:args].map{|x| exp_alloc(x)}.inject(Alloc.empty, &:&)
        key = exp[:typing].to_uniq_str
        raise "Assertion error" unless @top[:dict][:itype_space][key]
        type_def = @top[:dict][:itype_space][key].get
        @tbl[exp] = args_alloc & Alloc.one(Link.new(type_def))
      when Syntax
        @tbl[exp] = Alloc.empty
      else
        raise "Assertion error"
      end
    end
  end

  class Alloc
    attr_reader :h
    def initialize(hash)
      @h = hash
    end

    def self.empty
      self.new({})
    end

    def self.one(k)
      self.new(k => 1)
    end

    def |(other)
      Alloc.new self.h.merge(other.h){|k, v1, v2| [v1, v2].max}
    end

    def &(other)
      Alloc.new self.h.merge(other.h){|k, v1, v2| v1 + v2}
    end

    def each(&block)
      @h.each(&block)
    end
  end
end
