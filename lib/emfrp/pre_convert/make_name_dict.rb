module Emfrp
  module MakeNameDict
    extend self

    def make_name_dict(top)
      top[:dict] = {
        :node_space => {},
        :func_space => {},
        :type_space => {},
        :data_space => {},
        :const_space => {},
      }
      (top[:inputs] + top[:nodes]).each{|x| set_dict(top[:dict], x)}
      (top[:funcs] + top[:pfuncs]).each{|x| set_dict(top[:dict], x)}
      (top[:types] + top[:ptypes]).each{|x| set_dict(top[:dict], x)}
      top[:datas].each{|x| set_dict(top[:dict], x)}
    end

    def set_dict(dict, definition)
      name = definition[:name][:desc]
      case definition
      when InputDef, NodeDef
        if dict[:node_space][name]
          PreCheck.err(:dup, "Duplicate node/input name `#{name}':\n", dict[:node_space][name].get, definition)
        else
          dict[:node_space][name] = Link.new(definition)
        end
      when FuncDef, PrimFuncDef
        if dict[:func_space][name]
          PreCheck.err(:dup, "Duplicate func/pfunc name `#{name}':\n", dict[:func_space][name].get, definition)
        else
          dict[:func_space][name] = Link.new(definition)
          if definition.is_a?(FuncDef)
          end
        end
      when TypeDef, PrimTypeDef
        if dict[:type_space][name]
          PreCheck.err(:dup, "Duplicate type/ptype name `#{name}':\n", dict[:type_space][name].get, definition)
        else
          dict[:type_space][name] = Link.new(definition)
          if definition.is_a?(TypeDef)
            definition[:tvalues].each do |x|
              x[:type_def] = Link.new(definition)
              set_dict(dict, x)
            end
          end
        end
      when DataDef
        if dict[:data_space][name]
          PreCheck.err(:dup, "Duplicate data name `#{name}':\n", dict[:data_space][name].get, definition)
        else
          dict[:data_space][name] = Link.new(definition)
        end
      when TValue
        if dict[:const_space][name]
          PreCheck.err(:dup, "Duplicate constructor name `#{name}':\n", dict[:const_space][name].get, definition)
        else
          dict[:const_space][name] = Link.new(definition)
        end
      else
        raise "Assertion PreCheck.error: unexpected definition-type #{definition.class}"
      end
    end

    # remove definition from dict.
    # definition should not be depended by others
    def remove_dict(dict, definition)
      name = definition[:name][:desc]
      case definition
      when FuncDef
        dict[:func_space].delete(name) if dict[:func_space][name] && dict[:func_space][name].get == definition
      when TypeDef
        dict[:type_space].delete(name) if dict[:type_space][name] && dict[:type_space][name].get == definition
        definition[:tvalues].each do |x|
          remove_dict(dict, x)
        end
      when DataDef
        dict[:data_space].delete(name) if dict[:data_space][name] && dict[:data_space][name].get == definition
      when TValue
        dict[:const_space].delete(name) if dict[:const_space][name] && dict[:const_space][name].get == definition
      else
        raise "Assertion PreCheck.error: unexpected definition-type #{definition.class}"
      end
    end
  end
end
