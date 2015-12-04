require 'emfrp/typing/union_type'
require 'emfrp/typing/typing_error'

module Emfrp
  module Typing2
    extend self

    def typing(top, s=top)
      typing_syntax(top, s)
      typing_node_after(top)
      check_unbound_exp_type(s)
    end

    def typing_node_after(top)
      top[:outputs].each do |x|
        node = assoc(top, :node_space, x)
        try_unify(node[:typing], UnionType.from_type(x[:type]), "node for output `#{x[:name][:desc]}'", x)
      end
      top[:nodes].each do |x|
        x[:params].each do |y|
          node = assoc(top, :node_space, y)
          try_unify(y[:typing], node[:typing], UnionType.from_type(s[:type]), "node `#{y[:name][:desc]}'", y)
        end
      end
    end

    def typing_syntax(top, s)
      raise "Circular dependency" if s.has_key?(:typing_lock)
      s[:typing_lock] = true
      case s
      when InputDef
        s[:typing] = UnionType.from_type(d[:type])
        if s[:init_exp]
          init_exp_type = typing_exp(top, s[:init_exp])
          try_unify(init_exp_type, s[:typing], "init-exp for input `#{s[:name][:desc]}`", s[:init_exp])
        end
      when NodeDef
        s[:typing] = UnionType.new
        s[:params].each do |x|
          x[:typing] = UnionType.new
        end
        if s[:init_exp]
          init_exp_type = typing_exp(top, s[:init_exp])
          try_unify(init_exp_type, s[:typing], "init-exp for node `#{s[:name][:desc]}`", s[:init_exp])
        end
        body_exp_type = typing_exp(top, s[:exp])
        try_unify(body_exp_type, s[:typing], "body-exp for node `#{s[:name][:desc]}`", s[:exp])
      when FuncDef
        s[:params].each do |x|
          x[:typing] = UnionType.new
        end
        s[:typing] = typing_exp(top, s[:exp])
      when DataDef
        s[:typing] = typing_exp(top, s[:exp])
      when PrimFuncDef

      when TValue

      when Syntax
        typing_syntax(top, s.values, vtype_tbl)
      when Array
        s.each{|x| typing_syntax(top, x, vtype_tbl)}
      end
      s.delete(:typing_lock)
    end

    def assoc(top, key, s)
      top[:dict][key][s[:name][:desc]].get
    end


    def typing_exp(top, e)
      case e
      when

      when VarRef

      else
        raise "Assertion error: unexpected exp type #{s.class}"
      end
    end

    def get_var_typing(top, name, binder)
      case binder
      when DataDef
        syntax_typing(top, binder)
        binder[:typing]
      when NodeDef
        param = binder[:params].find{|x| x[:as] == name}
        param[:typing]
      when FuncDef
        param = binder[:params].find{|x| x == name}
        param[:typing]
      when Case
        pattern = find_pattern_by_ref_name(binder[:pattern], name)
        pattern[:typing]
      else
        raise "Assertion error"
      end
    end

    def check_unbound_exp_type(syntax, type=nil)
      case syntax
      when FuncDef, TypeDef
        check_unbound_exp_type(syntax.values, syntax[:typing])
      when NodeDef
        check_unbound_exp_type(syntax.values, nil)
      when DataDef
        check_unbound_exp_type(syntax.values, type)
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
  end
end
