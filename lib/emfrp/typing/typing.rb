require 'emfrp/typing/union_type'
require 'emfrp/typing/typing_error'
require 'emfrp/compile_error'

module Emfrp
  module Typing
    extend self

    class Tbl < Hash
      def [](key)
        if self.has_key?(key)
          self.fetch(key)
        else
          raise "#{key} is unbound"
        end
      end
    end

    def typing(top)
      ftype_tbl = Tbl.new
      vtype_tbl = Tbl.new
      ntype_tbl = Tbl.new
      typing_tvalues(ftype_tbl, top[:types])
      typing_pfuncs(ftype_tbl, top[:pfuncs])
      typing_funcs_and_datas(ftype_tbl, vtype_tbl, top[:funcs], top[:datas])
      typing_inputs(ftype_tbl, vtype_tbl, ntype_tbl, top[:inputs])
      typing_nodes(ftype_tbl, vtype_tbl, ntype_tbl, top[:nodes])
      check_unbound_exp_type(top)
    end

    def typing_tvalues(ftype_tbl, type_defs)
      type_defs.each do |td|
        type_var_tbl = {}
        td[:typing] = UnionType.from_type(td[:type], type_var_tbl)
        td[:tvalues].each do |tv|
          param_types = tv[:params].map{|x| UnionType.from_type(x[:type], type_var_tbl)}
          tv[:typing] = UnionType.new("Func", param_types + [td[:typing]])
          ftype_tbl[tv[:name]] = tv[:typing]
        end
      end
    end

    def typing_pfuncs(ftype_tbl, pfunc_def)
      pfunc_def.each do |pfunc_def|
        return_type = pfunc_def[:type]
        param_types = pfunc_def[:params].map{|param| param[:type]}
        func_type = UnionType.from_type(make_func_type(return_type, param_types))
        ftype_tbl[pfunc_def[:name]] = func_type
        pfunc_def[:typing] = func_type
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
      param_types = func_def[:params].map{|param| UnionType.new }
      param_vtype_tbl = func_def[:params].zip(param_types).map{|param, type|
        alpha_var = [param[:name], Link.new(func_def)]
        param[:typing] = type
        [alpha_var, type]
      }.to_h
      vtype_tbl.merge!(param_vtype_tbl)
      exp_type = typing_exp(ftype_tbl, vtype_tbl, func_def[:exp])
      func_type = UnionType.new("Func", param_types + [exp_type])
      ftype_tbl[func_name] = func_type
      func_def[:typing] = func_type
      # Unify with Type Annotation
      ano_param_types = func_def[:params].map{|x| x[:type] || UnionType.new}
      ano_return_type = func_def[:type] || UnionType.new
      func_def[:typing].unify(UnionType.from_type(make_func_type(ano_return_type, ano_param_types)))
    end

    def typing_data(ftype_tbl, vtype_tbl, data_def)
      alpha_var = [data_def[:name], Link.new(data_def)]
      exp_type = typing_exp(ftype_tbl, vtype_tbl, data_def[:exp])
      vtype_tbl[alpha_var] = exp_type
      data_def[:typing] = exp_type
      # Unify with Type Annotation
      if data_def[:type]
        UnionType.from_type(data_def[:type]).unify(data_def[:typing])
      end
    end

    def typing_inputs(ftype_tbl, vtype_tbl, ntype_tbl, input_defs)
      input_defs.each do |d|
        type = UnionType.from_type(d[:type])
        ntype_tbl[d[:name]] = type
        d[:typing] = type
        if d[:init_exp]
          init_exp_type = typing_exp(ftype_tbl, vtype_tbl, d[:init_exp])
          try_unify(init_exp_type, type, "init-exp for input `#{d[:name][:desc]}`", d[:init_exp])
        end
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
        if n[:init_exp]
          init_exp_type = typing_exp(ftype_tbl, vtype_tbl, n[:init_exp])
          try_unify(init_exp_type, n[:typing], "init-exp for node `#{n[:name][:desc]}`", n[:init_exp])
        end
      end
    end

    def typing_exp(ftype_tbl, vtype_tbl, exp)
      case exp
      when FuncCall, ValueConst
        # make expected-func-type
        expected_func_type = ftype_tbl[exp[:name]].clone_utype
        # make real-func-type
        return_type = UnionType.new
        arg_types = exp[:args].map{|e| typing_exp(ftype_tbl, vtype_tbl, e)}
        exp[:func_typing] = real_func_type = UnionType.new("Func", arg_types + [return_type])
        try_unify(real_func_type, expected_func_type, "function call `#{exp[:name][:desc]}`", exp)
        # return exp's utype
        return exp[:typing] = return_type
      when MatchExp
        left_type = typing_exp(ftype_tbl, vtype_tbl, exp[:exp])
        return_type = UnionType.new
        expected_case_type = UnionType.new("Case", [left_type, return_type])
        exp[:cases].each do |c|
          real_case_type = typing_exp(ftype_tbl, vtype_tbl, c)
          try_unify(real_case_type, expected_case_type, "case", c)
        end
        return exp[:typing] = return_type
      when Case
        pattern_type = typing_pattern(ftype_tbl, vtype_tbl, exp, exp[:pattern])
        return_type = typing_exp(ftype_tbl, vtype_tbl, exp[:exp])
        return exp[:typing] = UnionType.new("Case",  [pattern_type, return_type])
      when LiteralIntegral
        return exp[:typing] = UnionType.new("Int", [])
      when LiteralFloating
        return exp[:typing] = UnionType.new("Double", [])
      when LiteralChar
        return exp[:typing] = UnionType.new("Char", [])
      when VarRef
        alpha_var = [exp[:name], exp[:binder]]
        return exp[:typing] = vtype_tbl[alpha_var]
      when SkipExp
        return exp[:typing] = UnionType.new
      else
        raise "unexpected type #{exp.class} (bug)"
      end
    rescue UnionType::UnifyError => err
      raise "Uncatched UnifyError (bug)"
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
        expected_func_type = UnionType.new("Func", arg_types + [return_type])
        real_func_type = ftype_tbl[pattern[:name]].clone_utype
        real_func_type.unify(expected_func_type)
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
      raise TypeMatchingError.new("Type Error", pattern, err.a, err.b)
    end

    def check_unbound_exp_type(syntax, type=nil)
      case syntax
      when FuncDef, TypeDef
        check_unbound_exp_type(syntax.values, syntax[:typing])
      when NodeDef
        check_unbound_exp_type(syntax.values, nil)
      when DataDef
        if syntax[:name][:desc] =~ /^evaldata[0-9][0-9][0-9]$/
          # do nothing
        else
          check_unbound_exp_type(syntax.values, type)
        end
      when Syntax
        if syntax.has_key?(:typing) && syntax[:typing].has_var?
          if type == nil || syntax[:typing].typevars.any?{|t| !type.include?(t)}
            raise TypeDetermineError.new(syntax[:typing], syntax)
          end
        end
        check_unbound_exp_type(syntax.values, type)
      when Array
        syntax.map{|e| check_unbound_exp_type(e, type)}
      else
        # do nothing
      end
    end

    def try_unify(real_utype, expected_utype, place, *factors)
      real_utype.unify(expected_utype)
    rescue  UnionType::UnifyError => err
      raise TypeMatchingError.new(real_utype, expected_utype, place, *factors)
    end

    def ordinalize(int)
      int.to_s + case int % 10
      when 1 then "st"
      when 2 then "nd"
      when 3 then "rd"
      else "th"
      end
    end

    def self.make_func_type(return_type, param_types)
      name_ssymbol = SSymbol.new(:desc => "Func")
      return Type.new(:name => name_ssymbol, :size => nil, :args => param_types + [return_type])
    end
  end
end
