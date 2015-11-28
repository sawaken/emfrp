require 'emfrp/typing/union_type'

module Emfrp
  module Convert
    def convert_into_monomorphic(top, syntax=top, type_tbl={}, func_tbl={})
      if syntax.is_a?(Syntax) && syntax.has_key?(:typing)
        syntax[:mono_typing] = monofy(syntax[:typing], top, type_tbl)
      end
      case syntax
      when Top
        convert_into_monomorphic(top, syntax[:nodes])
        convert_into_monomorphic(top, syntax[:inputs])
        convert_into_monomorphic(top, syntax[:datas])
      when FuncCall
        f = syntax[:func].get
        key = [f[:name][:desc], syntax[:func_typing].to_uniq_str]
        if func_tbl[key]
          syntax[:func] = Link.new(func_tbl[key])
        elsif f.is_a?(PrimFuncDef)
          # do nothing
        else
          new_f_instance = copy_def(f)
          reassociate_func_param_var(f, new_f_instance)
          new_f_instance[:typing].unify(syntax[:func_typing])
          new_f_instance[:name][:desc] += "_" + syntax[:args].map{|e| e[:typing].to_flatten_uniq_str}.join("_")
          top[:ifuncs] << new_f_instance
          syntax[:func] = Link.new(func_tbl[key] = new_f_instance)
          convert_into_monomorphic(top, new_f_instance, type_tbl, func_tbl)
        end
        convert_into_monomorphic(top, syntax.values, type_tbl, func_tbl)
      when ValueConst
        mono_name = syntax[:typing].to_flatten_uniq_str
        t = top[:itypes].find{|x| x[:type][:name][:desc] == mono_name}
        raise "assertion error: undefined #{mono_name}" if t == nil
        syntax[:type] = Link.new(t, mono_name)
        convert_into_monomorphic(top, syntax.values, type_tbl, func_tbl)
      when Syntax
        convert_into_monomorphic(top, syntax.values, type_tbl, func_tbl)
      when Array
        syntax.clone.each{|x| convert_into_monomorphic(top, x, type_tbl, func_tbl)}
      end
    end

    def monofy(utype, top, type_tbl)
      raise "assertion error" if utype.has_var?
      if type_tbl[utype.to_uniq_str]
        return type_tbl[utype.to_uniq_str]
      end
      if top[:ptypes].find{|x| x[:name][:desc] == utype.typename}
        return utype
      end
      utype.typeargs.each do |child_utype|
        monofy(child_utype, top, type_tbl)
      end
      if ["Func", "Case"].include?(utype.typename)
        return Typing::UnionType.new(utype.typename, utype.typeargs.map{|x| monofy(x, top, type_tbl)})
      end
      t = top[:types].find{|x| x[:type][:name][:desc] == utype.typename}
      raise "assertion error: undefined #{utype.to_uniq_str}" if t == nil
      type_tbl[utype.to_uniq_str] = Typing::UnionType.new(utype.to_flatten_uniq_str, [])
      new_t_instance = copy_def(t)
      new_t_instance[:typing].unify(utype)
      new_t_instance[:tvalues].each do |tvalue|
        tvalue[:name][:desc] += "_" + utype.to_flatten_uniq_str
        convert_into_monomorphic(top, tvalue, type_tbl)
      end
      new_t_instance[:type][:name][:desc] = utype.to_flatten_uniq_str
      top[:itypes] << new_t_instance
      return type_tbl[utype.to_uniq_str]
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
        if new_x.has_key?(:func_typing)
          new_x[:func_typing] = x[:func_typing].clone_utype(tbl)
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
