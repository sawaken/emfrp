module Emfrp
  module PreCheck
    # Check duplication of toplevel-def-name, local-var-name.
    def associate_var(syntax, binders=[])
      case syntax
      when Top
        check_duplicate_name((syntax[:inputs] + syntax[:nodes]).map{|x| x[:name]})
        check_duplicate_name(syntax[:datas].map{|x| x[:name]})
        check_duplicate_name(syntax[:funcs].map{|x| x[:name]})
        check_duplicate_name(syntax[:types].map{|x| x[:type][:name]} + syntax[:ctypes].map{|x| x[:name]})
        check_duplicate_name(syntax[:types].map{|x| x[:tvalues].map{|x| x[:name]}}.flatten)
        syntax[:datas].each do |data_def|
          data_def[:binds] = [data_def[:name]]
        end
        associate_var(syntax.values, syntax[:datas])
      when NodeDef
        check_duplicate_name(syntax[:params].map{|x| x[:name]})
        vars = syntax[:params].map{|x| x[:as]}
        check_duplicate_name(vars)
        syntax[:binds] = vars
        associate_var(syntax.values, [syntax] + binders)
      when FuncDef
        vars = syntax[:params].map{|x| x[:name]}
        check_duplicate_name(vars)
        syntax[:binds] = vars
        associate_var(syntax.values, [syntax] + binders)
      when Case
        vars = find_ref_in_pattern(syntax[:pattern])
        check_duplicate_name(vars)
        syntax[:binds] = vars
        associate_var(syntax[:exp], [syntax] + binders)
      when VarRef
        binders.each do |binder|
          if binder[:binds].include?(syntax[:name])
            syntax[:binder] = Link.new(binder)
            return
          end
        end
        err("Unbound variable `#{syntax[:name][:desc]}`:\n", syntax)
      when Syntax
        associate_var(syntax.values, binders)
      when Array
        syntax.each{|e| associate_var(e, binders)}
      end
    end

    def find_ref_in_pattern(pattern) # -> [SSymbol]
      res = []
      if pattern[:ref]
        res << pattern[:ref]
      end
      if pattern.has_key?(:args)
        res = res + pattern[:args].map{|a| find_ref_in_pattern(a)}.flatten
      end
      return res
    end

    def check_duplicate_name(names)
      names.each do |name|
        dups = names.select{|x| x == name}
        if dups.size > 1
          err("Duplicate names `#{name[:desc]}`:\n", *dups)
        end
      end
    end
  end
end
