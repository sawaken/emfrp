module Emfrp
  module PreCheck
    def associate_func_and_data(syntax, caller_def=nil, funcs=[], datas=[])
      case syntax
      when Top
        syntax[:funcs].each do |f|
          f[:depends] = []
        end
        syntax[:datas].each do |d|
          d[:depends] = []
        end
        associate_func_and_data(syntax.values, caller_def, syntax[:funcs], syntax[:datas])
      when FuncDef
        associate_func_and_data(syntax.values, syntax, funcs, datas)
      when DataDef
        associate_func_and_data(syntax.values, syntax, funcs, datas)
      when FuncCall
        assoc_func(syntax[:name], syntax, syntax[:args].size, caller_def, funcs)
        associate_func_and_data(syntax.values, caller_def, funcs, datas)
      when VarRef
        case syntax[:binder].get
        when DataDef
          assoc_data(syntax[:name], caller_def, datas)
        end
      when Array
        syntax.each do |s|
          associate_func_and_data(s, caller_def, funcs, datas)
        end
      end
    end

    def assoc_func(funcname, caller, param_size, caller_def, funcs)
      fs = funcs.select{|f| f[:name] == funcname}
      if fs.size == 0
        err("Undefined function call", caller)
      end
      f = fs.first
      if f[:params].size != param_size
        err("Wrong number of arguments (#{param_size} for #{f[:params].size})", f, caller)
      end
      if caller_def != nil
        caller_def[:depends] << Link.new(f)
        caller_def[:depends].uniq!
      end
      caller[:func] = Link.new(f)
    end

    def assoc_data(dataname, caller_def, datas)
      d = datas.select{|d| d[:name] == dataname}.first
      if caller_def != nil
        caller_def[:depends] << Link.new(d)
        caller_def[:depends].uniq!
      end
    end
  end
end
