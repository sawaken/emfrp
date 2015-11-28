module Emfrp
  module Convert
    def convert_into_monomorphic(top, syntax=top)
      case syntax
      when FuncCall
        f = syntax[:func].get
        if f[:typing].has_var? && !syntax[:func_typing].has_var?
          f_instance = top[:ifuncs].find{|x| x[:instantiate_from].get == f && x[:typing].match?(syntax[:func_typing])}
          if f_instance
            syntax[:func] = Link.new(f_instance)
          else
            new_f_instance = copy_def(f)
            reassociate_func_param_var(f, new_f_instance)
            new_f_instance[:typing].unify(syntax[:func_typing])
            new_f_instance[:name][:desc] += "_" + syntax[:typing].to_flatten_uniq_str
            new_f_instance[:instantiate_from] = Link.new(f)
            top[:ifuncs] << new_f_instance
            syntax[:func] = Link.new(new_f_instance)
            convert_into_monomorphic(top, new_f_instance)
          end
        end
        convert_into_monomorphic(top, syntax.values)
      when ValueConst
        t = syntax[:type].get
        if t[:typing].has_var? && !syntax[:typing].has_var?
          t_instance = top[:itypes].find{|x| x[:instantiate_from].get == t && x[:typing].match?(syntax[:typing])}
          if t_instance
            syntax[:type] = Link.new(t_instance, t_instance[:type][:name][:desc])
          else
            new_t_instance = copy_def(t)
            new_t_instance[:typing].unify(syntax[:typing])
            new_t_instance[:type][:name][:desc] = syntax[:typing].to_flatten_uniq_str
            new_t_instance[:instantiate_from] = Link.new(t, t[:type][:name][:desc])
            top[:itypes] << new_t_instance
            syntax[:type] = Link.new(new_t_instance, new_t_instance[:type][:name][:desc])
            convert_into_monomorphic(top, new_t_instance)
          end
        end
        convert_into_monomorphic(top, syntax.values)
      when Syntax
        convert_into_monomorphic(top, syntax.values)
      when Array
        ary = syntax.clone
        ary.each{|x| convert_into_monomorphic(top, x)}
      end
    end

    def copy_def(x, tbl={})
      case x
      when Syntax
        new_x = x.dup
        x.keys.each do |k|
          new_x[k] = copy_def(x[k], tbl)
        end
        if new_x.has_key?(:typing)
          new_x[:typing] = x[:typing].clone_utype(tbl)
        end
        new_x
      when Array
        x.map{|a| copy_def(a, tbl)}
      else
        x
      end
    end

    def reassociate_func_param_var(original_func_def, cloned_func_def, exp=cloned_func_def)
      case exp
      when VarRef
        if exp[:binder].get == original_func_def
          exp[:binder] = Link.new(cloned_func_def)
        end
      when Syntax
        reassociate_func_param_var(original_func_def, cloned_func_def, exp.values)
      when Array
        exp.each{|x| reassociate_func_param_var(original_func_def, cloned_func_def, x)}
      end
    end
  end
end
