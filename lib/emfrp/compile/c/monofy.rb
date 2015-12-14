module Emfrp
  class Monofy
    IType = Struct.new(:typing, :type_def) do
      def ==(other)
        self.typing.to_uniq_str == other.typing.to_uniq_str && self.type_def[:name] == other.type_def[:name]
      end
    end

    IFunc = Struct.new(:typing, :param_typings, :func_def) do
      def ==(other)
        typing_name_array == other.typing_name_array && self.func_def[:name] == other.func_def[:name]
      end

      def typing_name_array
        ([typing] + param_typings).map{|x| x.to_uniq_str}
      end
    end

    def self.monofy(top)
      new(top).monofy
    end

    def initialize(top)
      @top = top
      @datas = []
      @itypes = []
      @ifuncs = []
      @update = false
    end

    def monofy
      @top[:outputs].each do |x|
        monofy_node(@top[:dict][:node_space][x[:name][:desc]].get)
      end
      while @update
        @update = false
        @datas.each do |d|
          key = Link.new(d)
          unless @top[:dict][:used_datas].find{|x| x == key}
            monofy_exp(d[:exp])
            @top[:dict][:used_datas] << key
          end
        end
        @ifuncs.each do |ifunc|
          key = ifunc.typing_name_array + [ifunc.func_def[:name][:desc]]
          unless @top[:dict][:ifunc_space][key]
            new_f = copy_def(ifunc.func_def)
            xs = ([new_f] + new_f[:params]).map{|x| x[:typing]}
            ys = [ifunc.typing] + ifunc.param_typings
            xs.zip(ys).each{|x, y| x.unify(y)}
            @top[:dict][:ifunc_space][key] = Link.new(new_f)
            monofy_exp(new_f[:exp])
          end
        end
        @itypes.each do |itype|
          key = itype.typing.to_uniq_str
          unless @top[:dict][:itype_space][key]
            new_t = copy_def(itype.type_def)
            new_t[:tvalues].each{|x| x[:typing].unify(itype.typing)}
            @top[:dict][:itype_space][key] = Link.new(new_t)
          end
        end
      end
      @top[:dict][:sorted_datas] = @datas.map{|x| Link.new(x)}
    end

    def monofy_node(node, visited={})
      return if visited[node]
      visited[node] = true
      monofy_exp(node[:init_exp]) if node[:init_exp]
      if node.is_a?(NodeDef)
        monofy_exp(node[:exp])
        node[:params].each do |param|
          monofy_node(@top[:dict][:node_space][param[:name][:desc]].get, visited)
        end
        @top[:dict][:sorted_nodes] << Link.new(node)
      end
    end

    def monofy_exp(exp, visited={})
      if exp.is_a?(Syntax) && exp.has_key?(:typing)
        case type_def = @top[:dict][:type_space][exp[:typing].typename].get
        when TypeDef
          itype = IType.new(exp[:typing], type_def)
          unless @itypes.find{|x| x == itype}
            @itypes << itype
            @update = true
          end
        when PrimTypeDef
          # do nothing
        else
          raise
        end
      end
      case exp
      when FuncCall
        case f = @top[:dict][:func_space][exp[:name][:desc]].get
        when FuncDef
          ifunc = IFunc.new(exp[:typing], exp[:args].map{|x| x[:typing]}, f)
          unless @ifuncs.find{|x| x == ifunc}
            @ifuncs << ifunc
            @update = true
          end
        when PrimFuncDef
          @top[:dict][:used_pfuncs] << Link.new(f)
          @top[:dict][:used_pfuncs].uniq!
        end
        monofy_exp(exp[:args])
      when VarRef
        d = exp[:binder].get
        if d.is_a?(DataDef) && !@datas.find{|x| x[:name] == d[:name]}
          @datas << d
          @update = true
        end
      when Syntax
        monofy_exp(exp.values)
      when Array
        exp.each{|x| monofy_exp(x)}
      end
    end

    def copy_def(x, mapping={}, tbl={})
      case x
      when Syntax
        new_x = x.dup
        mapping[x] = new_x
        x.keys.each do |k|
          new_x[k] = copy_def(x[k], mapping, tbl)
        end
        if new_x.has_key?(:typing)
          new_x[:typing] = x[:typing].clone_utype(tbl)
        end
        if new_x.has_key?(:binder) && mapping[new_x[:binder].get]
          new_x[:binder] = Link.new(mapping[new_x[:binder].get])
        end
        if new_x.has_key?(:type_def) && mapping[new_x[:type_def].get]
          new_x[:type_def] = Link.new(mapping[new_x[:type_def].get])
        end
        return new_x
      when Array
        return x.map{|a| copy_def(a, mapping, tbl)}
      else
        return x
      end
    end
  end
end
