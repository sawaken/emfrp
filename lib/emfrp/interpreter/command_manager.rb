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

      def exec(command_name, arg)
        if @command_tbl[command_name]
          @interpreter.instance_exec(arg, command_name, &@command_tbl[command_name])
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
                puts "#{arg} : " + func_def[:typing].to_uniq_str
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

          command "assert-equals" do |arg|
            if process_repl_line("(#{arg})")
              exp1 = @top[:datas].last[:args][0]
              exp2 = @top[:datas].last[:args][1]
              if Evaluater.assert_equals(@top, exp1, exp2)
                true
              else
                puts "Assertion failed"
                puts "Expected: #{Evaluater.eval_to_str(@top, exp1)}"
                puts "Real: #{Evaluater.eval_to_str(@top, exp2)}"
                false
              end
            else
              puts "Error: invalid argument for :assert-equal"
              false
            end
          end

        end
      end
    end
  end
end
