module Emfrp
  module AlphaConvert
    extend self

    def alpha_convert(top, syntax, tbl=nil)
      tbl ||= Hash.new{|h,k| h[k] = []}
      case syntax
      when InputDef
        alpha_convert(top, syntax[:init_exp], tbl) if syntax[:init_exp]
      when NodeDef
        alpha_convert(top, syntax[:init_exp], tbl) if syntax[:init_exp]
        if syntax[:params]
          check_duplicate_name(syntax[:params].map{|x| x[:name]})
          vars = syntax[:params].map{|x| x[:as]}
          check_duplicate_name(vars)
          vars.each do |v|
            tbl[v].push(syntax)
          end
          alpha_convert(top, syntax[:exp], tbl)
          vars.each do |v|
            tbl[v].pop
          end
        else
          syntax[:params] = []
          vars = (top[:nodes] + top[:inputs]).map{|x|
            [x[:name], SSymbol.new(:desc => x[:name][:desc] + "@last")]
          }.flatten
          vars.each do |v|
            tbl[v].push(syntax)
          end
          alpha_convert(top, syntax[:exp], tbl)
          vars.each do |v|
            tbl[v].pop
          end
        end
      when FuncDef
        vars = syntax[:params].map{|x| x[:name]}
        check_duplicate_name(vars)
        vars.each do |v|
          tbl[v].push(syntax)
        end
        alpha_convert(top, syntax[:exp], tbl)
        vars.each do |v|
          tbl[v].pop
        end
      when DataDef
        alpha_convert(top, syntax[:exp], tbl)
      when Case
        vars = find_ref_in_pattern(syntax[:pattern])
        check_duplicate_name(vars)
        vars.each do |v|
          tbl[v].push(syntax)
        end
        alpha_convert(top, syntax[:exp], tbl)
        vars.each do |v|
          tbl[v].pop
        end
      when VarRef
        if tbl[syntax[:name]].size == 0
          if top[:dict][:data_space][syntax[:name][:desc]]
            syntax[:binder] = top[:dict][:data_space][syntax[:name][:desc]]
          else
            PreConvert.err(:unbound, "Unbound variable `#{syntax[:name][:desc]}':\n", syntax)
          end
        else
          binder = tbl[syntax[:name]].last
          if binder.is_a?(NodeDef) && !binder[:params].find{|x| x[:as] == syntax[:name]}
            if syntax[:name][:desc] =~ /^(.+)@last$/
              name = SSymbol.new(:desc => $1)
              last = true
            else
              name = syntax[:name]
              last = false
            end
            binder[:params] << NodeRef.new(:as => syntax[:name], :name => name, :last => last)
          end
          syntax[:binder] = Link.new(binder)
        end
      when ValueConst, ValuePattern
        name = syntax[:name][:desc]
        if tvalue_link = top[:dict][:const_space][name]
          tvalue = tvalue_link.get
          if syntax[:args].size != tvalue[:params].size
            s = "#{syntax[:args].size} for #{tvalue[:params].size}"
            PreConvert.err(:arg_num, "Wrong number of arguments (#{s}) for `#{name}':\n", syntax)
          end
        else
          PreConvert.err("Undefined value-constructor `#{name}':\n", syntax)
        end
        alpha_convert(top, syntax.values, tbl)
      when FuncCall
        name = syntax[:name][:desc]
        if func_link = top[:dict][:func_space][name]
          f = func_link.get
          if syntax[:args].size != f[:params].size
            s = "#{syntax[:args].size} for #{f[:params].size}"
            PreConvert.err(:arg_num, "Wrong number of arguments (#{s}) for `#{name}':\n", syntax)
          end
        else
          PreConvert.err(:undef, "Undefined function `#{name}':\n", syntax)
        end
        alpha_convert(top, syntax.values, tbl)
      when Syntax
        alpha_convert(top, syntax.values, tbl)
      when Array
        syntax.each{|e| alpha_convert(top, e, tbl)}
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
          PreConvert.err(:dup, "Duplicate variable names `#{name[:desc]}':\n", *dups)
        end
      end
    end
  end
end
