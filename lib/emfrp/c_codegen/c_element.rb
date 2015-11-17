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

      ExpStmt = Struct.new(:exp) do
        def to_s(t=0)
          I[t] + "#{exp};"
        end
      end

      BlockStmt = Struct.new(:name, :cond, :stmts) do
        def sort_stmts
          tmp = stmts.select{|x| x.is_a?(VarDeclareStmt)} + stmts.reject{|x| x.is_a?(VarDeclareStmt)}
          stmts = tmp
        end

        def to_s(t=0, indent_first=true)
          sort_stmts()
          res = ""
          res << (indent_first ? I[t] : "") + "#{name} (#{cond})\n"
          res << I[t] + "{\n"
          stmts.each do |x|
            res << x.to_s(t+1) + "\n"
          end
          res << I[t] + "}"
          return res
        end
      end

      WhileStmt = Struct.new(:cond_exp, :stmts) do
        def to_s(t=0, indent_first=true)
          BlockStmt.new("while", cond_exp, stmts).to_s(t, indent_first)
        end
      end

      IfStmt = Struct.new(:cond_exp, :then_stmts) do
        def to_s(t=0, indent_first=true)
          BlockStmt.new("if", cond_exp, then_stmts).to_s(t, indent_first)
        end
      end

      IfChainStmt = Struct.new(:if_stmts) do
        def to_s(t=0)
          I[t] + if_stmts.map{|x|
            x.to_s(t, false)
          }.join("\n" + I[t] + "else ")
        end
      end

      StructDeclare = Struct.new(:kind, :type_name, :declares, :instance_name) do
        def to_s(t=0)
          res = ""
          res << I[t] + "#{[kind, type_name].join(" ")}\n"
          res << I[t] + "{\n"
          res << declares.map{|x| x.to_s(t+1)}.join("\n") + "\n"
          res << I[t] + "}" + instance_name.to_s + ";"
          return res
        end
      end
    end
  end
end
