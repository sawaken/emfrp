require 'emfrp/c_codegen/c_element'

module Emfrp
  module CCodeGen
    def initialize
      @codes = []
    end

    def gen(top)
      @types = top[:types]

    end

    def to_s
      @codes.map(&:to_s).join("\n")
    end

    def node_gen(node_def)
      func_name = "Node_" + node_def[:name][:desc]
      param_types = node_def[:typing].typeargs.clone
      return_type = param_types.pop
      params = node_def[:params].map{|x| x[:as] || x[:name]}.zip(param_types).map do |n, t|
        type_gen(t) + " " + name2cname(n[:desc])
      end
      @codes << CElement::Func.new(func_name, params, type_gen(return_type), body_exp_gen(node_def[:exp]))
    end

    def native_func_gen(func_def, func_type, args)
      f = copy_func_def(func_def)
      f[:typing].unify(func_type)
      func_name = "Func_" + f[:name][:desc] + "_" + func_type.to_uniq_str
      return_type = f[:typing].typeargs.pop
      params = f[:params].map{|x| x[:name]}.zip(f[:typing].typeargs).map do |n, t|
        type_gen(t) + " " + n[:desc]
      end
      @codes << CElement::Func.new(func_name, params, type_gen(return_type), body_exp_gen(f[:body]))
      return func_name + "(#{args.join(", ")})"
    end

    def c_macro_func_gen(func_def, func_type, args)
      typesize_params = []
      typesize_args = []
      make_type_var_tbl(func_def[:typing], func_type).each do |k, v|
        if v.typename.is_a?(Integer)
          typesize_params << k
          typesize_args << v.typename
        end
      end
      params = func_def[:params].map{|x| x[:name]} + typesize_params
      macro_name = "Prim_#{func_def[:name]}"
      @codes << CElement::Macro.new(macro_name, params.join, func_def[:body][:desc])
      args = args + typesize_args
      return macro_name + "(#{args.join(", ")})"
    end

    def foreign_func_gen(func_def, func_type)

    end

    def body_exp_gen(exp)
      "hoge"
    end

    def exp_gen(exp)

    end

    def type_gen(utype)
      # generate struct
      return utype.to_uniq_str
    end

    def name2cname(name)
      name.gsub("@", "_at_")
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
