module Emfrp
  class CCodeGen
    module CElement
      I = (0..100).map{|i| "  " * i}

      CMacro = Struct.new(:name, :param_list, :body) do
        def to_s(t=0)
          "#define #{name}(#{param_list.join(", ")}) (#{body})"
        end

        def duplicate?(other)
          self.name == other.name
        end
      end

      FuncDeclare = Struct.new(:name, :type, :param_name_list, :param_type_list, :stmts) do
        def to_s(t=0)
          param_list = param_name_list.zip(param_type_list).map{|n, t| "#{t} #{n}"}
          sorted_stmts = stmts.select{|x| x.is_a?(VarDeclareStmt)} + stmts.reject{|x| x.is_a?(VarDeclareStmt)}
          header = "#{type} #{name}(#{param_list.join(", ")})\n{"
          middles = sorted_stmts.map{|x| x.to_s(t+1)}
          footer = "}"
          return ([header] + middles + [footer]).join("\n")
        end
      end

      FuncProtoDeclare = Struct.new(:name, :type, :param_type_list) do
        def to_s(t=0)
          "#{type} #{name}(#{param_type_list.join(", ")});"
        end
      end

      VarAssignStmt = Struct.new(:var_name, :exp) do
        def to_s(t=0)
          I[t] + "#{var_name} = #{exp};"
        end
      end

      VarDeclareStmt = Struct.new(:typename, :var_name) do
        def to_s(t=0)
          I[t] + "#{typename} #{var_name};"
        end
      end

      ReturnStmt = Struct.new(:exp) do
        def to_s(t=0)
          I[t] + "return #{exp};"
        end
      end

      IfStmt = Struct.new(:cond_exp, :then_stmts) do
        def to_s(t=0)
          sorted_stmts = then_stmts.select{|x| x.is_a?(VarDeclareStmt)} +
            then_stmts.reject{|x| x.is_a?(VarDeclareStmt)}
          res = ""
          res << "if (#{cond_exp})\n"
          res << I[t] + "{\n"
          sorted_stmts.each do |x|
            res << x.to_s(t+1) + "\n"
          end
          res << I[t] + "}"
          return res
        end
      end

      IfChainStmt = Struct.new(:if_stmts) do
        def to_s(t=0)
          I[t] + if_stmts.map{|x| x.to_s(t)}.join("\n" + I[t] + "else ")
        end
      end
    end
  end
end
