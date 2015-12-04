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
        :var_space => {}
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
          PreCheck.err("Duplicate node/input name `#{name}':\n", dict[:node_space][name].get, definition)
        else
          dict[:node_space][name] = Link.new(definition)
        end
      when FuncDef, PrimFuncDef
        if dict[:func_space][name]
          PreCheck.err("Duplicate func/pfunc name `#{name}':\n", dict[:func_space][name].get, definition)
        else
          dict[:func_space][name] = Link.new(definition)
        end
      when TypeDef, PrimTypeDef
        if dict[:type_space][name]
          PreCheck.err("Duplicate type/ptype name `#{name}':\n", dict[:type_space][name].get, definition)
        else
          dict[:type_space][name] = Link.new(definition)
          definition[:tvalues].each{|x| set_dict(dict, x)} if definition.is_a?(TypeDef)
        end
      when DataDef
        if dict[:data_space][name]
          PreCheck.err("Duplicate data name `#{name}':\n", dict[:data_space][name].get, definition)
        else
          dict[:data_space][name] = Link.new(definition)
        end
      when TValue
        if dict[:const_space][name]
          PreCheck.err("Duplicate constructor name `#{name}':\n", dict[:const_space][name].get, definition)
        else
          dict[:const_space][name] = Link.new(definition)
        end
      else
        raise "Assertion PreCheck.error: unexpected definition-type #{definition.class}"
      end
    end
  end
end
