module Emfrp
  module PreCheck
    module AssociateAndFlatten
      extend self

      def convert(top)
        make_name_dict(top)
      end

      def additional_convert(top, definition)
        set_dict(top[:dict], definition)
        if definition.is_a?(TypeDef)
          definition[:tvalues].each{|x| set_dict(top[:dict], x)}
        end
      end

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
        top[:types].each{|x| x[:tvalues].each{|y| set_dict(top[:dict], y)}}
      end

      def set_dict(dict, definition)
        name = definition[:name][:desc]
        case definition
        when InputDef, NodeDef
          if dict[:node_space][name]
            err("Duplicate node/input name `#{name}':\n", dict[:node_space][name].get, definition)
          else
            dict[:node_space][name] = Link.new(definition)
          end
        when FuncDef, PrimFuncDef
          if dict[:func_space][name]
            err("Duplicate func/pfunc name `#{name}':\n", dict[:func_space][name].get, definition)
          else
            dict[:func_space][name] = Link.new(definition)
          end
        when TypeDef, PrimTypeDef
          if dict[:type_space][name]
            err("Duplicate type/ptype name `#{name}':\n", dict[:type_space][name].get, definition)
          else
            dict[:type_space][name] = Link.new(definition)
          end
        when DataDef
          if dict[:data_space][name]
            err("Duplicate data name `#{name}':\n", dict[:data_space][name].get, definition)
          else
            dict[:data_space][name] = Link.new(definition)
          end
        when TValue
          if dict[:const_space][name]
            err("Duplicate constructor name `#{name}':\n", dict[:const_space][name].get, definition)
          else
            dict[:const_space][name] = Link.new(definition)
          end
        else
          raise "Assertion error: unexpected definition-type #{definition.class}"
        end
      end

      def alpha_convert_var()

      end
    end
  end
end
