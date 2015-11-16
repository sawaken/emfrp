require 'emfrp/c_codegen/c_element'
require 'emfrp/c_codegen/convert_to_cname'

module Emfrp
  class CCodeGen
    def initialize
      @codes = []
      @templates = []
      @func_name_tbl = {}
      @type_tbl = {}
    end

    def gen(top)
      @types = top[:types].map{|x| [x[:type][:name][:desc], x]}.to_h
      @ctypes = top[:ctypes].map{|x| [x[:name][:desc], x]}.to_h
      top[:nodes].each{|x| node_gen(x)}
    end

    def to_s
      macros = @codes.select{|x| x.is_a?(CElement::CMacro)}
      protos = @codes.select{|x| x.is_a?(CElement::FuncProtoDeclare)}.sort{|a, b| a.name <=> b.name}
      funcs = @codes.select{|x| x.is_a?(CElement::FuncDeclare)}.sort{|a, b| a.name <=> b.name}
      (macros + protos + funcs).map(&:to_s).join("\n")
    end

    def node_gen(node_def)
      name = "Node_" + node_def[:name][:desc]
      param_name_list = node_def[:params].map{|x| name2cname(x[:as][:desc])}
      param_type_list = node_def[:param_typing].map{|t| type_ref_name_gen(t)}
      # add output param
      output_type = type_ref_name_gen(node_def[:typing]) + "*"
      output_name = "output"
      param_type_list << output_type
      param_name_list << output_name
      body = []
      body << CElement::VarAssignStmt.new("*" + output_name, exp_gen(node_def[:exp], body))
      body << CElement::ReturnStmt.new("1")
      @codes << CElement::FuncProtoDeclare.new(name, "int", param_type_list)
      @codes << CElement::FuncDeclare.new(name, "int", param_name_list, param_type_list, body)
    end

    def input_gen(input_def)
      name = input_def[:body][:desc]
      type = input_def[:decolator].is_a?(InitDef) ? "int" : "void"
      @codes << CElement::FuncProtoDeclare.new(name, type, ["void"])
      @templates << CElement::FuncDeclare.new(name, type, param_name_list, param_type_list, [])
    end

    def output_gen(output_def)

    end

    def initialize_gen(initialize_def)

    end

    def native_func_gen(func_def, func_type, args)
      key = [func_def[:name], func_type.to_uniq_str]
      if @func_name_tbl[key]
        return @func_name_tbl[key] + "(#{args.join(", ")})"
      end
      f = copy_func_def(func_def)
      f[:typing].unify(func_type)
      name = name2cname(f[:name][:desc]) + func_serial_number_gen(f[:name])
      param_name_list = f[:params].map{|x| x[:name][:desc]}
      param_type_list = f[:typing].typeargs.map{|t| type_ref_name_gen(t)}
      type = param_type_list.pop
      body = []
      body << CElement::ReturnStmt.new(exp_gen(func_def[:body], body))
      @codes << CElement::FuncProtoDeclare.new(name, type, param_type_list)
      @codes << CElement::FuncDeclare.new(name, type, param_name_list, param_type_list, body)
      @func_name_tbl[key] = name
      return name + "(#{args.join(", ")})"
    end

    def c_macro_func_gen(func_def, func_type, args)
      if @func_name_tbl[func_def[:name]]
        return @func_name_tbl[func_def[:name]] + "(#{args.join(", ")})"
      end
      typesize_params, typesize_args = *typesize_params_args(func_def[:typing], func_type)
      params = func_def[:params].map{|x| x[:name][:desc]} + typesize_params
      name = "Prim_" + name2cname(func_def[:name][:desc])
      @codes << CElement::CMacro.new(name, params, func_def[:body][:desc])
      args = args + typesize_args
      @func_name_tbl[func_def[:name]] = name
      return name + "(#{args.join(", ")})"
    end

    def foreign_func_gen(func_def, func_type, args)
      if @func_name_tbl[func_def[:name]]
        return @func_name_tbl[func_def[:name]] + "(#{args.join(", ")})"
      end
      name = func_def[:body][:desc]
      param_name_list = func_def[:params].map{|x| x[:name][:desc]}
      param_type_list = func_def[:typing].map{|t| type_ref_name_gen(t)}
      type = param_type_list.pop
      # Add typesize as param
      typesize_params, typesize_args = *typesize_params_args(func_def[:typing], func_type)
      param_name_list += typesize_params
      param_type_list += typesize_params.map{"int"}
      @codes << CElement::FuncProtoDeclare.new(name, type, param_type_list)
      @templates << CElement::FuncDeclare.new(name, type, param_name_list, param_type_list, [])
      @func_name_tbl[func_def[:name]] = name
      return name + "(#{args.join(", ")})"
    end

    def foreign_data_gen(data_def)

    end

    def native_data_gen(data_def)

    end

    def exp_gen(exp, stmts) # -> String (C-Expression)
      case exp
      when FuncCall
        args = exp[:args].map{|x| exp_gen(x, stmts)}
        f = exp[:func].get
        case f[:body]
        when SSymbol
          foreign_func_gen(f, exp[:func_typing], args)
        when CExp
          c_macro_func_gen(f, exp[:func_typing], args)
        else
          native_func_gen(f, exp[:func_typing], args)
        end
      when ValueConst
        args = exp[:args].map{|x| exp_gen(x, stmts)}
        exp[:name][:desc] + "_" + type_name_gen(exp[:typing]) + "(#{args.join(", ")})"
      when LiteralTuple, LiteralArray
        args = exp[:entity].map{|x| exp_gen(x, stmts)}
        type_name_gen(exp[:typing]) + "(#{args.join(", ")})"
      when GFConst
        arg = exp_gen(exp[:exp], stmts)
        "(#{arg} % #{exp[:size]})"
      when LiteralIntegral
        exp[:entity][:desc]
      when VarRef
        exp[:name][:desc]
      when MatchExp
        return_var_name = serial_var_name_gen()
        stmts << CElement::VarDeclareStmt.new(type_ref_name_gen(exp[:typing]), return_var_name)
        match_exp_gen(exp, return_var_name, stmts)
        return return_var_name
      else
        raise "unexpected type #{exp.class} (bug)"
      end
    end

    def match_exp_gen(exp, return_var_name, stmts) # -> ()
      left = exp[:exp]
      if left.is_a?(VarRef)
        left_name = left[:name][:desc]
      else
        left_name = serial_var_name_gen()
        stmts << CElement::VarDeclareStmt.new(type_ref_name_gen(left[:typing]), left_name)
        stmts << CElement::VarAssignStmt.new(left_name, exp_gen(left, stmts))
      end
      stmts << CElement::IfChainStmt.new(exp[:cases].map{|c|
        then_stmts = []
        cond_exps = pattern_to_cond_exps(left_name, then_stmts, c[:pattern])
        cond_exp = cond_exps.size == 0 ? "1" : cond_exps.join(" && ")
        if c[:exp].is_a?(SkipExp)
          then_stmts << CElement::ReturnStmt.new("0")
        else
          then_stmts << CElement::VarAssignStmt.new(return_var_name, exp_gen(c[:exp], then_stmts))
        end
        CElement::IfStmt.new(cond_exp, then_stmts)
      })
    end

    def pattern_to_cond_exps(receiver_exp, stmts, pattern)
      conds = []
      case pattern
      when ValuePattern
        type_def = pattern[:type].get
        accessor = type_gen(pattern[:typing])[:is_static] ? "." : "->"
        if type_def[:tvalues].size > 0
          tvalue_id = type_def[:tvalues].index{|x| x[:name] == pattern[:name]}
          conds << "#{receiver_exp}" + accessor + "tvalue_type == " + tvalue_id.to_s
        end
        new_receiver_exp = "#{receiver_exp}" + accessor + pattern[:name][:desc]
        pattern[:args].each_with_index do |x, i|
          conds += pattern_to_cond_exps(new_receiver_exp + ".member#{i}", stmts, x)
        end
      when TuplePattern
        pattern[:args].each_with_index do |x, i|
          conds += pattern_to_cond_exps("#{receiver_exp}->member#{i}", stmts, x)
        end
      when IntegralPattern
        conds << "#{receiver_exp} == #{pattern[:val][:entity][:desc]}"
      end
      if pattern[:ref]
        stmts << CElement::VarDeclareStmt.new(type_ref_name_gen(pattern[:typing]), pattern[:ref][:desc])
        stmts << CElement::VarAssignStmt.new(pattern[:ref][:desc], receiver_exp)
      end
      return conds
    end

    def type_ref_name_gen(utype) # -> String (Typename)
      type_gen(utype)[:ref_name]
    end

    def type_name_gen(utype) # -> String (Row Typename)
      type_gen(utype)[:name]
    end

    def type_gen(utype) # -> Hash
      if @type_tbl[utype.to_uniq_str]
        return @type_tbl[utype.to_uniq_str]
      end
      if @ctypes[utype.to_uniq_str]
        name = @ctypes[utype.to_uniq_str][:ctype][:desc]
        return @type_tbl[utype.to_uniq_str] = {
          :ref_name => name,
          :name => name,
          :is_static => true
        }
      elsif type_def = @types[utype.typename]
        if utype.typeargs.size > 0
          row_name = utype.typename + type_serial_number_gen(utype)
        else
          row_name = utype.typename
        end
        struct_gen(type_def, utype, row_name)
        constructor_gen(type_def, utype, row_name)
        return @type_tbl[utype.to_uniq_str] = {
          :ref_name => row_name + (type_def[:static] ? "" : "*"),
          :name => row_name,
          :is_static => type_def[:static]
        }
      elsif utype.typename == "Tuple" || utype.typename == "Array"
        row_name = utype.typename + type_serial_number_gen(utype)
        if utype.typename == "Tuple"
          tuple_struct_gen(utype, row_name)
          tuple_constructor_gen(utype, row_name)
        elsif utype.typename == "Array"
          array_struct_gen(utype, row_name)
          array_constructor_gen(utype, row_name)
        end
        return @type_tbl[utype.to_uniq_str] = {
          :ref_name => row_name + "*",
          :name => row_name,
          :is_static => false
        }
      else
        raise "undefined type #{utype.to_uniq_str} (bug)"
      end
    end

    def struct_gen(type_def, utype, row_name)

    end

    def constructor_gen(type_def, utype, row_name)

    end

    def tuple_struct_gen(utype, row_name)

    end

    def tuple_constructor_gen(utype, row_name)

    end

    def array_struct_gen(utype, row_name)

    end

    def array_constructor_gen(utype, row_name)

    end

    def serial_var_name_gen # -> String
      @var_count ||= 0
      res = sprintf("_v%02d", @var_count)
      @var_count += 1
      return res
    end

    def type_serial_number_gen(utype) # -> String
      @type_count_tbl ||= Hash.new{0}
      res = sprintf("%02d", @type_count_tbl[utype.typename])
      @type_count_tbl[utype.typename] += 1
      return res
    end

    def func_serial_number_gen(name) # -> String
      @func_count_tbl ||= Hash.new{0}
      res = sprintf("%02d", @func_count_tbl[name])
      @func_count_tbl[name] += 1
      return res
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
