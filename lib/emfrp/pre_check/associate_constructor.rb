module Emfrp
  module PreCheck
    def associate_constructor(syntax, types=[])
      case syntax
      when Top
        associate_constructor(syntax.values, syntax[:types])
      when ValueConst, ValuePattern
        types.each do |type|
          type[:tvalues].each do |tvalue|
            if tvalue[:name] == syntax[:name]
              if syntax[:args].size != tvalue[:params].size
                s = "#{syntax[:args].size} for #{tvalue[:params].size}"
                err("Wrong number of arguments (#{s}) for `#{tvalue[:name][:desc]}`:\n", syntax)
              end
              syntax[:type] = Link.new(type, type[:type][:name][:desc])
              associate_constructor(syntax.values, types)
              return
            end
          end
        end
        err("Undefined value-constructor `#{syntax[:name][:desc]}`:\n", syntax)
      when Syntax
        associate_constructor(syntax.values, types)
      when Array
        syntax.each do |x|
          associate_constructor(x, types)
        end
      end
    end
  end
end
