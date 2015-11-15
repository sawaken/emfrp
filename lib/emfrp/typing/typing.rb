require 'emfrp/typing/union_type'

module Emfrp
  module Typing
    extend self
    TypingError = Class.new(RuntimeError)

    class Tbl < Hash
      def [](key)
        if self.has_key?(key)
          self.fetch(key)
        else
          raise "#{key} is unbound"
        end
      end
    end

    def err(message, *factors)
      raise TypingError.new(:message => message, :factors => factors)
    end

    def typing(top)
      ftype_tbl = Tbl.new
      vtype_tbl = Tbl.new
      ntype_tbl = Tbl.new
      typing_tvalues(ftype_tbl, top[:types])
      typing_funcs_and_datas(ftype_tbl, vtype_tbl, top[:funcs], top[:datas])
      typing_inputs(ntype_tbl, top[:inputs])
      typing_nodes(ftype_tbl, vtype_tbl, ntype_tbl, top[:nodes])
      check_unbound_exp_type(top)
      #pp ftype_tbl
      #pp vtype_tbl
    end

    def typing_tvalues(ftype_tbl, type_defs)
      type_defs.each do |td|
        return_type = td[:type]
        td[:tvalues].each do |tv|
          param_types = tv[:params].map{|param| param[:type]}
          ftype_tbl[tv[:name]] = UnionType.from_type(make_func_type(return_type, param_types))
        end
      end
    end

    def typing_funcs_and_datas(ftype_tbl, vtype_tbl, func_defs, data_defs)
      f = proc do |d|
        if !d.has_key?(:typing)
          d[:depends].each do |dd|
            f.call(dd.get)
          end
          case d
          when DataDef
            alpha_var = [d[:name], Link.new(d)]
            unless vtype_tbl.has_key?(alpha_var)
              typing_data(ftype_tbl, vtype_tbl, d)
            end
          when FuncDef
            unless ftype_tbl.has_key?(d[:name])
              typing_func(ftype_tbl, vtype_tbl, d)
            end
          end
        end
      end
      (func_defs + data_defs).each do |d|
        f.call(d)
      end
    end

    def typing_func(ftype_tbl, vtype_tbl, func_def)
      func_name = func_def[:name]
      case func_def[:body]
      when SSymbol, CExp
        return_type = func_def[:type]
        param_types = func_def[:params].map{|param| param[:type]}
        func_type = UnionType.from_type(make_func_type(return_type, param_types))
        ftype_tbl[func_name] = func_type
        func_def[:typing] = func_type
      else
        param_types = func_def[:params].map{|param| UnionType.new }
        param_vtype_tbl = func_def[:params].zip(param_types).map{|param, type|
          alpha_var = [param[:name], Link.new(func_def)]
          [alpha_var, type]
        }.to_h
        vtype_tbl.merge!(param_vtype_tbl)
        exp_type = typing_exp(ftype_tbl, vtype_tbl, func_def[:body])
        func_type = UnionType.new("FuncType", param_types + [exp_type])
        ftype_tbl[func_name] = func_type
        func_def[:typing] = func_type
        # Unify with Type Annotation
        ano_param_types = func_def[:params].map{|x| x[:type] || UnionType.new}
        ano_return_type = func_def[:type] || UnionType.new
        func_def[:typing].unify(UnionType.from_type(make_func_type(ano_return_type, ano_param_types)))
      end
    end

    def typing_data(ftype_tbl, vtype_tbl, data_def)
      alpha_var = [data_def[:name], Link.new(data_def)]
      case data_def[:body]
      when SSymbol, CExp
        type = UnionType.from_type(data_def[:type])
        vtype_tbl[alpha_var] = type
        data_def[:typing] = type
      else
        exp_type = typing_exp(ftype_tbl, vtype_tbl, data_def[:body])
        vtype_tbl[alpha_var] = exp_type
        data_def[:typing] = exp_type
        # Unify with Type Annotation
        if data_def[:type]
          UnionType.from_type(data_def[:type]).unify(data_def[:typing])
        end
      end
    end

    def typing_inputs(ntype_tbl, input_defs)
      input_defs.each do |d|
        type = UnionType.from_type(d[:type])
        ntype_tbl[d[:name]] = type
        d[:typing] = type
      end
    end

    def typing_nodes(ftype_tbl, vtype_tbl, ntype_tbl, node_defs)
      node_defs.each do |n|
        if !ntype_tbl.has_key?(n[:name])
          ntype_tbl[n[:name]] = UnionType.new
        end
        n[:typing] = ntype_tbl[n[:name]]
      end
      node_defs.each do |n|
        param_vtype_tbl = n[:params].map{|x|
          alpha_var = [x[:as], Link.new(n)]
          [alpha_var, ntype_tbl[x[:name]]]
        }.to_h
        vtype_tbl.merge!(param_vtype_tbl)
        n[:typing].unify(typing_exp(ftype_tbl, vtype_tbl, n[:exp]))
        n[:param_typing] = n[:params].map{|x| ntype_tbl[x[:name]]}
        # Unify with Type Annotation
        if n[:type]
          UnionType.from_type(n[:type]).unify(n[:typing])
        end
      end
    end

    def typing_exp(ftype_tbl, vtype_tbl, exp)
      case exp
      when FuncCall, ValueConst
        arg_exps = exp[:args]
        arg_types = arg_exps.map{|a| typing_exp(ftype_tbl, vtype_tbl, a)}
        return_type = UnionType.new
        func_name = exp[:name]
        expected_func_type = UnionType.new("FuncType", arg_types + [return_type])
        real_func_type = ftype_tbl[func_name].copy
        real_func_type.unify(expected_func_type)
        exp[:func_typing] = expected_func_type
        return exp[:typing] = return_type
      when IfExp
        typing_exp(ftype_tbl, vtype_tbl, exp[:cond]).unify(UnionType.new("Bool", []))
        return_type = UnionType.new
        typing_exp(ftype_tbl, vtype_tbl, exp[:then]).unify(return_type)
        typing_exp(ftype_tbl, vtype_tbl, exp[:else]).unify(return_type)
        return exp[:typing] = return_type
      when MatchExp
        left_type = typing_exp(ftype_tbl, vtype_tbl, exp[:exp])
        return_type = UnionType.new
        expected_case_type = UnionType.new("CaseType", [left_type, return_type])
        exp[:cases].each do |c|
          typing_exp(ftype_tbl, vtype_tbl, c).unify(expected_case_type)
        end
        return exp[:typing] = return_type
      when Case
        pattern_type = typing_pattern(ftype_tbl, vtype_tbl, exp, exp[:pattern])
        return_type = typing_exp(ftype_tbl, vtype_tbl, exp[:exp])
        return exp[:typing] = UnionType.new("CaseType",  [pattern_type, return_type])
      when LiteralIntegral
        return exp[:typing] = UnionType.new("Int", [])
      when LiteralFloating
        return exp[:typing] = UnionType.new("Double", [])
      when LiteralChar
        return exp[:typing] = UnionType.new("Char", [])
      when LiteralTuple
        types = exp[:entity].map{|e| typing_exp(ftype_tbl, vtype_tbl, e)}
        return_type = UnionType.new("Tuple", types)
        return exp[:typing] = return_type
      when LiteralArray
        entity_type = UnionType.new
        exp[:entity].each do |e|
          typing_exp(ftype_tbl, vtype_tbl, e).unify(entity_type)
        end
        type_size = UnionType.new(exp[:entity].size, [])
        return exp[:typing] = UnionType.new("Array", [type_size, entity_type])
      when LiteralString
        type_size = UnionType.new(exp[:entity].size, [])
        char_type = UnionType.new("Char", [])
        return exp[:typing] = UnionType.new("Array", [type_size,  char_type])
      when GFConst
        if exp[:size]
          type_size = UnionType.new(exp[:size][:desc].to_i, [])
        else
          type_size = UnionType.new
        end
        int_type = UnionType.new("Int", [])
        typing_exp(ftype_tbl, vtype_tbl, exp[:exp]).unify(int_type)
        return exp[:typing] = UnionType.new("GF", [type_size])
      when VarRef
        alpha_var = [exp[:name], exp[:binder]]
        return exp[:typing] = vtype_tbl[alpha_var]
      when SkipExp
        return exp[:typing] = UnionType.new
      else
        raise "error #{exp.class}"
      end
    rescue UnionType::UnifyError => err
      err("Type Error", exp, err.a, err.b)
    end

    def typing_pattern(ftype_tbl, vtype_tbl, binder_case, pattern)
      case pattern
      when AnyPattern
        type = UnionType.new
        if pattern[:ref]
          alpha_var = [pattern[:ref], Link.new(binder_case)]
          vtype_tbl[alpha_var] = type
        end
        return pattern[:typing] = type
      when ValuePattern
        arg_types = pattern[:args].map{|a| typing_pattern(ftype_tbl, vtype_tbl, binder_case, a)}
        return_type = UnionType.new
        expected_func_type = UnionType.new("FuncType", arg_types + [return_type])
        real_func_type = ftype_tbl[pattern[:name]].copy
        real_func_type.unify(expected_func_type)
        if pattern[:ref]
          alpha_var = [pattern[:ref], Link.new(binder_case)]
          vtype_tbl[alpha_var] = return_type
        end
        return pattern[:typing] = return_type
      when TuplePattern
        arg_types = pattern[:args].map{|a| typing_pattern(ftype_tbl, vtype_tbl, binder_case, a)}
        return_type = UnionType.new("Tuple", arg_types)
        if pattern[:ref]
          alpha_var = [pattern[:ref], Link.new(binder_case)]
          vtype_tbl[alpha_var] = return_type
        end
        return pattern[:typing] = return_type
      when IntegralPattern
        type = UnionType.new("Int", [])
        return pattern[:typing] = type
      end
    rescue UnionType::UnifyError => err
      err("Type Error", pattern, err.a, err.b)
    end

    def check_unbound_exp_type(syntax, type=nil)
      case syntax
      when FuncDef
        check_unbound_exp_type(syntax.values, syntax[:typing])
      when Syntax
        if syntax.has_key?(:typing) && syntax[:typing].has_var?
          if type == nil || !type.include?(syntax[:typing])
            err("non-determined type occurred", syntax)
          end
        end
        check_unbound_exp_type(syntax.values, type)
      when Array
        syntax.map{|e| check_unbound_exp_type(e, type)}
      else
        # do nothing
      end
    end

    def self.make_func_type(return_type, param_types)
      name_ssymbol = SSymbol.new(:desc => "FuncType")
      return Type.new(:name => name_ssymbol, :size => nil, :args => param_types + [return_type])
    end
  end
end
