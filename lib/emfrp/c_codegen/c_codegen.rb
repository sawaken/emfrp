require 'emfrp/c_codegen/c_element'

module Emfrp
  module CCodeGen
    def initialize
      @codes = []
      @templates = []
    end

    def gen(top)
      type_gen(top)

    end

    def to_s
      @codes.map(&:to_s).join("\n")
    end

    def node_gen(node_def)
      name = "Node_" + node_def[:name][:desc]
      param_name_list = node_def[:params].map{|x| name2cname(x[:as][:desc])}
      param_type_list = node_def[:typing].typeargs.map{|t| type2cname(t)}
      type = param_type_list.pop
      body = body_exp_gen(node_def[:exp])
      @codes << CElement::Func.new(name, type, param_name_list, param_type_list, body)
    end

    def foreign_input_gen(input_def)
      name = input_def[:body][:desc]
      type = input_def[:decolator].is_a?(InitDef) ? "int" : "void"
      @codes << CElement::FuncProtoDeclare.new(name, type, ["void"])
      @templates << CElement::FuncDeclare.new(name, type, param_name_list, param_type_list, [])
    end

    def constructor_gen(tvalue, type)
      name = "Const_" + tvalue[:name] + type2cname(type)
    end

    def native_func_gen(func_def, func_type, args)
      f = copy_func_def(func_def)
      f[:typing].unify(func_type)
      name = "Func_" + f[:name][:desc] + "_" + type2cname(t)
      param_name_list = f[:params].map{|x| x[:name][:desc]}
      param_type_list = f[:typing].typeargs.map{|t| type2cname(t)}
      type = param_type_list.pop
      body = body_exp_gen(f[:body])
      @codes << CElement::FuncDeclare.new(name, type, param_name_list, param_type_list, body)
      return func_name + "(#{args.join(", ")})"
    end

    def c_macro_func_gen(func_def, func_type, args)
      typesize_params, typesize_args = *typesize_params_args(func_def[:typing], func_type)
      params = func_def[:params].map{|x| x[:name]} + typesize_params
      name = "PrimMacro_" + func_def[:name][:desc]
      @codes << CElement::Macro.new(name, params.join, func_def[:body][:desc])
      args = args + typesize_args
      return macro_name + "(#{args.join(", ")})"
    end

    def foreign_func_gen(func_def, func_type, args)
      name = func_def[:body][:desc]
      param_name_list = func_def[:params].map{|x| x[:name][:desc]}
      param_type_list = func_def[:typing].map{|t| type2cname(t)}
      type = param_type_list.pop
      # Add typesize as param
      typesize_params, typesize_args = *typesize_params_args(func_def[:typing], func_type)
      param_name_list += typesize_params
      param_type_list += typesize_params.map{"int"}
      @codes << CElement::FuncProtoDeclare.new(name, type, param_type_list)
      @templates << CElement::FuncDeclare.new(name, type, param_name_list, param_type_list, [])
    end

    def exp_gen(exp, &back_proc)
      back_proc = proc{|e| CElement::ReturnStmt(e)} unless back_proc
      case exp
      when FuncCall
        f = exp[:binder].get
        case f
        when SSymbol
          back_proc.call(foreign_func_gen(f, ))
        when
    end

    def type_gen(top)
      # generate structs
    end

    def typesize_params_args(utype_with_var, utype_without_var)
      typesize_params = []
      typesize_args = []
      make_type_var_tbl(utype_with_var, utype_without_var).each do |k, v|
        if v.typename.is_a?(Integer)
          typesize_params << k
          typesize_args << v.typename
        end
      end
      return [typesize_params, typesize_args]
    end

    def make_type_var_tbl(utype_with_var, utype_without_var)
      if utype_with_var.var? && utype_with_var.original_typevar_name
        {utype_with_var.original_typevar_name => utype_without_var}
      else
        res = {}
        utype_with_var.typeargs.zip(utype_without_var.typeargs).each do |a, b|
          res.merge!(make_type_var_tbl(a, b))
        end
        return res
      end
    end

    def copy_func_def(x, tbl={})
      case x
      when Syntax
        new_x = x.dup
        x.keys.each do |k|
          new_x[k] = copy_func_def(x[k], tbl)
        end
        if new_x.has_key?(:typing)
          new_x[:typing] = x[:typing].copy(tbl)
        end
        new_x
      when Array
        x.map{|a| copy_func_def(a, tbl)}
      else
        x
      end
    end
  end
end
