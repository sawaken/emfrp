module Emfrp
  class Interpreter
    class CommandManager
      def initialize(interpreter, &proc)
        @interpreter = interpreter
        @command_names = []
        @command_tbl = {}
        instance_exec(&proc)
      end

      def command(*names, &proc)
        names.each do |name|
          @command_names << ":" + name
          @command_tbl[name] = proc
        end
      end

      def exec(command_name, arg, readline_id)
        if @command_tbl[command_name]
          @interpreter.instance_exec(arg, command_name, readline_id, &@command_tbl[command_name])
        else
          @interpreter.puts "Error: undefined command `#{command_name}'"
          false
        end
      end

      def completion_proc
        proc do |s|
          @command_names.select{|name| name.index(s) == 0}
        end
      end

      def self.make(interpreter)
        CommandManager.new(interpreter) do
          command "func-type", "func-ast" do |arg, com|
            if func_def = (@top[:funcs] + @top[:pfuncs]).find{|x| x[:name][:desc] == arg}
              case com
              when "func-type"
                puts func_def[:params].map{|x| x[:typing].inspect}.join(", ") + " -> " + func_def[:typing].inspect
              when "func-ast"
                pp func_def
              end
              true
            else
              puts "Error: undefined function `#{arg}'"
              false
            end
          end

          command "data-type", "data-ast" do |arg, com|
            if data_def = @top[:datas].find{|x| x[:name][:desc] == arg}
              case com
              when "data-type"
                puts "#{arg} : " + data_def[:typing].to_uniq_str
              when "data-ast"
                pp data_def
              end
              true
            else
              puts "Error: undefined data `#{arg}'"
              false
            end
          end

          command "type-ast" do |arg|
            type_def = @top[:types].find{|x| x[:type][:name][:desc] == arg}
            ptype_def = @top[:ptypes].find{|x| x[:name][:desc] == arg}
            if type_def || ptype_def
              pp type_def || ptype_def
              true
            else
              puts "Error: undefined type `#{arg}`"
              false
            end
          end

          command "node-type", "node-ast" do |arg, com|
            if node_def = (@top[:nodes] + @top[:inputs]).find{|x| x[:name][:desc] == arg}
              case com
              when "node-type"
                puts "#{arg} : " + node_def[:typing].to_uniq_str
              when "node-ast"
                pp node_def
              end
              true
            else
              puts "Error: undefined node/input `#{arg}'"
              false
            end
          end

          command "ast" do
            pp @top
            true
          end

          command "ifuncs-ast" do
            pp @top[:ifuncs]
            true
          end

          command "itypes-ast" do
            pp @top[:itypes]
            true
          end

          command "assert-equals" do |arg, c, rid|
            if exp = str_to_exp("Pair(#{arg})")
              val1 = Evaluater.eval_exp(@top, exp[:args][0])
              val2 = Evaluater.eval_exp(@top, exp[:args][1])
              if val1 == val2
                true
              else
                puts "Assertion failed".colorize(:red)
                puts "Description: #{arg}"
                puts "Type: #{exp[:args][0][:typing].inspect.colorize(:green)}"
                puts "Expected: #{Evaluater.value_to_s(val1)}"
                puts "Real:     #{Evaluater.value_to_s(val2)}"
                false
              end
            else
              puts "Error: invalid argument for :assert-equals"
              false
            end
          end

          command "exec-embeded-commands" do
            exec_embeded_commands()
          end

          command "set-func-doc" do |arg|
            true
          end

          command "assert-node" do |arg|
            if arg =~ /^\s*([a-z][a-zA-Z0-9]*)\s+(.*)=>(.*)$/
              n = @top[:dict][:node_space][$1]
              if n && n.get.is_a?(NodeDef)
                node_def = n.get
                a_exp = str_to_exp("(Unit, #{$2})")
                if a_exp && a_exp[:args].size - 1 == node_def[:params].size
                  begin
                    args = a_exp[:args].drop(1)
                    args.zip(node_def[:params]).each do |a, param|
                      a[:typing].unify(param[:typing])
                    end
                    if $3.strip == "skip"
                      v2 = :skip
                    else
                      if r_exp = str_to_exp($3)
                        r_exp[:typing].unify(node_def[:typing])
                        v2 = Evaluater.eval_exp(@top, r_exp)
                      else
                        puts "Error: invalid return-expression"
                        next false
                      end
                    end
                  rescue Typing::UnionType::UnifyError
                    puts "Error: invalid argument type for node `#{$1}'"
                    next false
                  end
                  v1 = Evaluater.eval_node(@top, node_def, args)
                  if v1 == v2
                    next true
                  else
                    puts "Node Assertion failed".colorize(:red)
                    puts "Description: #{arg}"
                    puts "Expected: #{Evaluater.value_to_s(v2)}"
                    puts "Real:     #{Evaluater.value_to_s(v1)}"
                    next false
                  end
                else
                  puts "Error: invalid argument-expression"
                  next false
                end
              else
                puts "Error: invalid node name #{$1}"
                next false
              end
            else
              puts "Error: invalid argument for :assert-node"
              puts "usage:"
              puts "  :assert-node <Node-name> <arg-exp>* => <expected-return-exp>"
              next false
            end
          end

        end
      end
    end
  end
end
