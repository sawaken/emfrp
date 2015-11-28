module Emfrp
  module Convert
    def find_used(syntax)
      if syntax.is_a?(Syntax)
        if syntax.has_key?(:used)
          return
        else
          syntax[:used] = true
        end
      end
      case syntax
      when Top
        find_used(syntax[:nodes] + syntax[:inputs])
      when VarRef
        syntax[:binder].get.is_a?(DataDef)
        find_used(syntax[:binder].get)
      when FuncCall
        find_used(syntax[:func].get)
        find_used(syntax[:args])
      when ValueConst
        find_used(syntax[:type].get)
        find_used(syntax[:args])
      when Syntax
        find_used(syntax.values)
      when Array
        syntax.each{|x| find_used(x)}
      end
    end
  end
end
