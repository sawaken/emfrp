require 'emfrp/typing/union_type'
require 'emfrp/typing/typing_error'

module Emfrp
  module Typing
    extend self

    def typing(top, s=top)
      typing_syntax(top, s)
      typing_node(top)
      check_unbound_exp_type(s, [])
    end

    def additional_typing(top, definition)
      typing_syntax(top, definition)
      check_unbound_exp_type(definition, [])
    end

    def typing_node(top)
      # typing Inputs
      top[:inputs].each do |i|
        i[:typing] = UnionType.from_type(i[:type])
        if i[:init_exp]
          init_exp_type = typing_exp(top, i[:init_exp])
          try_unify(i[:typing], init_exp_type, "init-exp for input `#{i[:name][:desc]}`", i[:init_exp])
        end
      end
      # typing Nodes
      top[:nodes].each do |n|
        n[:typing] = UnionType.new
        n[:params].each do |x|
          x[:typing] = UnionType.new
        end
        if n[:init_exp]
          init_exp_type = typing_exp(top, n[:init_exp])
          try_unify(n[:typing], init_exp_type, "init-exp for node `#{n[:name][:desc]}`", n[:init_exp])
        end
        body_exp_type = typing_exp(top, n[:exp])
        try_unify(n[:typing], body_exp_type, "body-exp for node `#{n[:name][:desc]}`", n[:exp])
        if n[:type]
          try_unify(UnionType.from_type(n[:type]), n[:typing], "type-annotation for node `#{n[:name][:desc]}'", n)
        end
      end
      # unify Outputs and Nodes
      top[:outputs].each do |x|
        node = assoc(top, :node_space, x)
        try_unify(node[:typing], UnionType.from_type(x[:type]), "output `#{x[:name][:desc]}'", x)
      end
      # unify Node-params and Nodes
      top[:nodes].each do |n|
        n[:params].each do |param|
          node = assoc(top, :node_space, param)
          s = "parameter `#{param[:name][:desc]}' for node `#{n[:name][:desc]}'"
          try_unify(node[:typing], param[:typing], s, param)
        end
      end
    end

    def typing_syntax(top, s)
      if s.is_a?(Syntax)
        return if s.has_key?(:typing)
        if s.has_key?(:typing_lock)
          raise CompileError.new("`#{s[:name][:desc]}' is defined recursively:\n", s)
        end
        s[:typing_lock] = true
      end
      case s
      when FuncDef
        tbl = {}
        s[:params].each do |x|
          x[:typing] = x[:type] ? UnionType.from_type(x[:type], tbl) : UnionType.new
        end
        s[:typing] = typing_exp(top, s[:exp])
        if s[:type]
          str = "type-annotation for node `#{s[:name][:desc]}'"
          try_unify(UnionType.from_type(s[:type], tbl), s[:typing], str, s)
        end
      when DataDef
        s[:typing] = typing_exp(top, s[:exp])
      when PrimFuncDef
        s[:params].each do |x|
          x[:typing] = UnionType.from_type(x[:type])
        end
        s[:typing] = UnionType.from_type(s[:type])
      when TValue
        tbl = {}
        s[:params].each do |x|
          x[:typing] = UnionType.from_type(x[:type], tbl)
        end
        s[:typing] = UnionType.from_type(s[:type_def].get[:type], tbl)
      when Syntax
        typing_syntax(top, s.values)
      when Array
        s.each{|x| typing_syntax(top, x)}
      end
      s.delete(:typing_lock) if s.is_a?(Syntax)
    end

    def assoc(top, key, s)
      top[:dict][key][s[:name][:desc]].get
    end


    def typing_exp(top, e)
      case e
      when FuncCall
        f = assoc(top, :func_space, e)
        typing_syntax(top, f)
        return_type, *arg_types = clone_utypes(f[:typing], *f[:params].map{|x| x[:typing]})
        e[:args].zip(arg_types).each do |a, t|
          try_unify(t, typing_exp(top, a), "argument of function `#{f[:name][:desc]}'", a)
        end
        return e[:typing] = return_type
      when ValueConst
        tvalue = assoc(top, :const_space, e)
        typing_syntax(top, tvalue)
        return_type, *arg_types = clone_utypes(tvalue[:typing], *tvalue[:params].map{|x| x[:typing]})
        e[:args].zip(arg_types).each do |a, t|
          try_unify(t, typing_exp(top, a), "argument of value-constructor `#{tvalue[:name][:desc]}'", a)
        end
        return e[:typing] = return_type
      when MatchExp
        left_type = typing_exp(top, e[:exp])
        return_type = UnionType.new
        e[:cases].each do |c|
          try_unify(left_type, typing_pattern(top, c[:pattern]), "pattern of MatchExp", c[:pattern])
          try_unify(return_type, typing_exp(top, c[:exp]), "body-expression of MatchExp", c[:exp])
        end
        return e[:typing] = return_type
      when LiteralIntegral
        return e[:typing] = UnionType.new("Int", [])
      when LiteralFloating
        return e[:typing] = UnionType.new("Double", [])
      when LiteralChar
        return e[:typing] = UnionType.new("Char", [])
      when VarRef
        return e[:typing] = get_var_typing(top, e[:name], e[:binder].get)
      when SkipExp
        return e[:typing] = UnionType.new
      else
        raise "Assertion error: unexpected exp type #{e.class}"
      end
    end

    def get_var_typing(top, name, binder)
      case binder
      when DataDef
        typing_syntax(top, binder)
        binder[:typing]
      when NodeDef
        param = binder[:params].find{|x| x[:as] == name}
        param[:typing]
      when FuncDef
        param = binder[:params].find{|x| x[:name] == name}
        param[:typing]
      when Case
        pattern = find_pattern_by_ref_name(binder[:pattern], name)
        pattern[:typing]
      else
        raise "Assertion error: unexpected binder type #{binder.class}"
      end
    end

    def typing_pattern(top, pattern)
      case pattern
      when AnyPattern
        return pattern[:typing] = UnionType.new
      when ValuePattern
        tvalue = assoc(top, :const_space, pattern)
        typing_syntax(top, tvalue)
        return_type, *etypes = clone_utypes(tvalue[:typing], *tvalue[:params].map{|x| x[:typing]})
        rtypes = pattern[:args].map{|a| typing_pattern(top, a)}
        pattern[:args].each_with_index do |a, i|
          try_unify(etypes[i], rtypes[i], "arg for pattern `#{pattern[:name][:desc]}'", a)
        end
        return pattern[:typing] = return_type
      when IntegralPattern
        return pattern[:typing] = UnionType.new("Int", [])
      else
        raise "Assertion error: unexpected pattern type #{pattern.class}"
      end
    end

    def clone_utypes(*utypes)
      tbl = {}
      utypes.map{|t| t.clone_utype(tbl)}
    end

    def find_pattern_by_ref_name(pattern, name)
      if pattern[:ref] && pattern[:ref] == name
        pattern
      elsif pattern.is_a?(ValuePattern)
        pattern[:args].find{|p| find_pattern_by_ref_name(p, name)}
      else
        nil
      end
    end

    def check_unbound_exp_type(syntax, allow_types)
      case syntax
      when FuncDef
        allow_types = [syntax[:typing]] + syntax[:params].map{|x| x[:typing]}
        check_unbound_exp_type(syntax.values, allow_types)
      when TValue
        check_unbound_exp_type(syntax.values, [syntax[:typing]])
      when NodeDef
        check_unbound_exp_type(syntax.values, [])
      when DataDef
        check_unbound_exp_type(syntax.values, [])
      when Syntax
        if syntax.has_key?(:typing) && syntax[:typing].has_var?
          syntax[:typing].typevars.each do |t|
            unless allow_types.any?{|at| at.include?(t)}
              raise TypeDetermineError.new(syntax[:typing], syntax)
            end
          end
        end
        check_unbound_exp_type(syntax.values, allow_types)
      when Array
        syntax.map{|e| check_unbound_exp_type(e, allow_types)}
      else
        # do nothing
      end
    end

    def try_unify(expected_utype, real_utype, place, *factors)
      real_utype.unify(expected_utype)
    rescue UnionType::UnifyError => err
      raise TypeMatchingError.new(expected_utype, real_utype, place, *factors)
    end
  end
end
