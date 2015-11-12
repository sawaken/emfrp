module Emfrp
  module CCodeGen
    module CElement
      CMacro = Struct.new(:name, :param_list, :body) do
        def to_s
          "#define #{name}(#{param_list.join(", ")}) (#{body})"
        end

        def duplicate?(other)
          self.name == other.name
        end
      end

      Func = Struct.new(:name, :param_list, :type, :body) do
        def to_s
          "#{type} #{name}(#{param_list.join(", ")}) #{body}"
        end
      end
    end
  end
end
