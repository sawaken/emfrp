require 'emfrp/typing/union_type'

module Emfrp
  module Typing
    TypingError = Class.new(RuntimeError)

    def self.typing_fail(message, *factors)
      raise TypingError.new(:message => message, :factors => factors)
    end

    def self.typing(toplevel)
      type_tbl = {}
      typing_tvalues(type_tbl, toplevel.select{|s| s.is_a?(TypeDef)})
      typing_funcs(type_tbl, toplevel.select{|s| s.is_a?(FuncDef)})
      typing_datas(type_tbl, toplevel.select{|s| s.is_a?(DataDef)})
      typing_nodes(type_tbl, toplevel.select{|s| s.is_a?(NodeDef)})
      return type_tbl
    end


    def self.typing_tvalues(type_tbl, type_defs)
      type_defs.each do |td|
        return_type = td[:type]
        td[:tvalues].each do |tv|
          param_types = tv[:params].map{|param| param[:type]}
          type_tbl[tv[:name][:desc]] = UnionType.from_type(make_func_type(return_type, param_types))
        end
      end
    end

    def self.typing_funcs(type_tbl, func_defs)
      sort_funcs(func_defs).each do |func_def|
        func_name_str = func_def[:name][:desc]
        case func_def[:body]
        when SSymbol, CExp
          return_type = func_def[:type]
          param_types = func_def[:params].map{|param| param[:type]}
          func_type = UnionType.from_type(make_func_type(return_type, param_types))
          type_tbl[func_name_str] = func_type
          func_def[:typing] = func_type
        else
          param_types = func_def[:params].map{|param| UnionType.new }
          var_type_tbl = func_def[:params].zip(param_types).map{|param, type|
            [param[:name][:desc], type]
          }.to_h
          exp_type = typing_exp(type_tbl, [var_type_tbl], func_def[:body])
          func_type = UnionType.new("FuncType", param_types + [exp_type])
          type_tbl[func_name_str] = func_type
          func_def[:typing] = func_type
        end
      end
    end

    def self.typing_datas(type_tbl, data_defs)

    end

    def self.typing_nodes(type_tbl, node_defs)

    end

    def self.typing_exp(type_tbl, var_type_tbl_stack, exp)
      case exp
      when BinaryOperatorExp, UnaryOperatorExp, FuncCall,  MethodCall, ValueConst
        arg_exps = case exp
        when BinaryOperatorExp
          [exp[:left], exp[:right]]
        when UnaryOperatorExp
          [exp[:exp]]
        when FuncCall
          exp[:args]
        when MethodCall
          [exp[:receiver]] + exp[:args]
        when ValueConst
          exp[:args]
        end
        arg_types = arg_exps.map{|a| typing_exp(type_tbl, var_type_tbl_stack, a)}
        return_type = UnionType.new
        func_name_str = exp[:name][:desc]
        expected_func_type = UnionType.new("FuncType", arg_types + [return_type])
        real_func_type = type_tbl[func_name_str].copy
        begin
          real_func_type.unify(expected_func_type)
        rescue UnionType::UnifyError => err
          typing_fail("unify fail", expected_func_type, real_func_type)
        end
        return exp[:typing] = return_type
      when LiteralIntegral
        return exp[:typing] = UnionType.new("Int", [])
      when VarRef
        return exp[:typing] = resolve_var_type(var_type_tbl_stack, exp[:name][:desc])
      else
        raise "error #{exp.class}"
      end
    end

    def self.resolve_var_type(var_type_tbl_stack, var_name_str)
      var_type_tbl_stack.each do |tbl|
        if tbl.has_key?(var_name_str)
          return tbl[var_name_str]
        end
      end
      raise "var type assoc error #{var_name_str}"
    end

    def self.check_unbound_exp_type(exp, bound_type_vars)
      case exp
      when Syntax
        if exp[:typing].var? && !bound_type_vars.include?(exp[:typing])
          typing_fail("non-determined type occurred", exp)
        end
        check_unbound_exp_type(exp.values, bound_type_vars)
      when Array
        exp.map{|e| check_unbound_exp_type(e, bound_type_vars)}
      else
        # do nothing
      end
    end

    def self.make_func_type(return_type, param_types)
      name_ssymbol = SSymbol.new(:desc => "FuncType")
      return Type.new(:name => name_ssymbol, :args => param_types + [return_type])
    end

    def self.sort_funcs(func_defs)
      name_to_dep_tbl = func_defs.map{|f|
        deps = f.has_key?(:exp) ? depending_func_names(f[:exp]) : []
        [f[:name][:desc], deps]
      }.to_h
      sorted_func_names = []
      while name_to_dep_tbl.size > 0
        name_to_dep_tbl.each do |k, v|
          v.reject!{|n| sorted_func_names.include?(n)}
        end
        sorted_func_names += name_to_dep_tbl.select{|k, v| v == []}.keys
        name_to_dep_tbl.reject!{|k, v| v == []}
      end
      name_to_def_tbl = func_defs.map{|f| [f[:name][:desc], f]}.to_h
      return sorted_func_names.map{|f| name_to_def_tbl[f]}
    end

    def self.depending_func_names(exp)
      case exp
      when Sytnax
        exp.map{|k, v| depending_func_names(v)}.flatten
      when Array
        exp.map{|v| depending_func_names(v)}.flatten
      when MethodCall, FuncCall, UnaryOperatorExp, BinaryOperatorExp
        [exp[:name][:desc]]
      else
        raise "error"
      end
    end
  end
end
