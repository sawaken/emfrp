require 'emfrp/compile/c/codegen'
require 'emfrp/compile/graphviz/graphviz'

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
          return :exec_error
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
              nil
            else
              puts "Error: undefined function `#{arg}'"
              :command_format_error
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
              nil
            else
              puts "Error: undefined data `#{arg}'"
              :command_format_error
            end
          end

          command "type-ast" do |arg|
            type_def = @top[:types].find{|x| x[:type][:name][:desc] == arg}
            ptype_def = @top[:ptypes].find{|x| x[:name][:desc] == arg}
            if type_def || ptype_def
              pp type_def || ptype_def
              nil
            else
              puts "Error: undefined type `#{arg}`"
              :command_format_error
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
              nil
            else
              puts "Error: undefined node/input `#{arg}'"
              :command_format_error
            end
          end

          command "ast" do
            pp @top
            nil
          end

          command "ifuncs-ast" do
            @top[:dict][:ifunc_space].each do |k, v|
              puts "#{k} =>"
              pp v.get
            end
            nil
          end

          command "itypes-ast" do
            @top[:dict][:itype_space].each do |k, v|
              puts "#{k} =>"
              pp v.get
            end
            nil
          end

          command "assert-equals" do |arg, c, rid|
            if exp = str_to_exp("Pair(#{arg})")
              val1 = Evaluater.eval_exp(@top, exp[:args][0])
              val2 = Evaluater.eval_exp(@top, exp[:args][1])
              if val1 == val2
                nil
              else
                puts "Assertion failed".colorize(:red)
                puts "Description: #{arg}"
                puts "Type: #{exp[:args][0][:typing].inspect.colorize(:green)}"
                puts "Expected: #{Evaluater.value_to_s(val1)}"
                puts "Actual:   #{Evaluater.value_to_s(val2)}"
                :assertion_error
              end
            else
              puts "Error: invalid argument for :assert-equals"
              :command_format_error
            end
          end

          command "exec-embeded-commands" do
            exec_embeded_commands()
          end

          command "set-func-doc" do |arg|
            nil
          end

          command "assert-node" do |arg|
            if arg =~ /^\s*([a-z][a-zA-Z0-9]*)\s+(.*)=>(.*)$/
              n = @top[:dict][:node_space][$1]
              if n && n.get.is_a?(NodeDef)
                node_def = n.get
                types = ["Unit", "Unit"] + node_def[:params].map{|x| x[:typing].to_uniq_str}
                exp_str = ($2.strip == "" ? "(Unit, Unit)" : "(Unit, Unit, #{$2.strip})")
                if a_exp = str_to_exp(exp_str, "(#{types.join(", ")})")
                  v1 = Evaluater.eval_node_as_func(@top, node_def, a_exp[:args].drop(2))
                  if $3.strip == "skip"
                    v2 = :skip
                  elsif r_exp = str_to_exp($3.strip, "#{node_def[:typing].to_uniq_str}")
                    v2 = Evaluater.eval_exp(@top, r_exp)
                  else
                    puts "Error: invalid expected-return-expression"
                    next :command_format_error
                  end
                  if v1 == v2
                    next nil
                  else
                    puts "Node Assertion failed".colorize(:red)
                    puts "Description: #{arg}"
                    puts "Expected: #{Evaluater.value_to_s(v2)}"
                    puts "Actual:   #{Evaluater.value_to_s(v1)}"
                    next :assertion_error
                  end
                else
                  puts "Error: invalid node-argument-expression"
                  next :command_format_error
                end
              else
                puts "Error: invalid node name #{$1}"
                next :command_format_error
              end
            else
              puts "Error: invalid argument for :assert-node"
              puts "usage:"
              puts "  :assert-node <Node-name> <arg-exp>* => <expected-return-exp>"
              next :command_format_error
            end
          end

          command "assert-module" do |arg|
            if arg =~ /^(.*)=>(.*)$/
              input_types = ["Unit", "Unit"] + @top[:inputs].map{|x| x[:typing].to_uniq_str}
              exp_str = ($1.strip == "" ? "(Unit, Unit)" : "(Unit, Unit, #{$1.strip})")
              input_exps = str_to_exp(exp_str, "(#{input_types.join(", ")})")
              output_types = @top[:outputs].map{|x| x[:typing].to_uniq_str}
              output_exps = str_to_exp("(Unit, #{$2})", "(Unit, #{output_types.join(", ")})")
              if input_exps == nil || output_exps == nil
                puts "Error: invalid expression"
                next :command_format_error
              end
              # evaluate
              last_state = @current_state ? @current_state.clone : nil
              @current_state = {}
              @node_replacement ||= {}
              output_vals = Evaluater.eval_module(@top, input_exps[:args].drop(2),
                @current_state, last_state, @node_replacement)
              expected_output_vals = output_exps[:args].drop(1).map{|x| Evaluater.eval_exp(@top, x)}
              # assert
              if expected_output_vals != output_vals
                puts "Module Assertion failed".colorize(:red)
                puts "Description: #{arg}"
                puts "Expected: #{expected_output_vals.map{|x| Evaluater.value_to_s(x)}.join(", ")}"
                puts "Actual:   #{output_vals.map{|x| Evaluater.value_to_s(x)}.join(", ")}"
                :assertion_error
              else
                nil
              end
            else
              puts "Error: invalid argument for :assert-module"
              :command_format_error
            end
          end

          command "assert-type" do |arg|
            if arg =~ /^(.*)=>(.*)$/
              if exp = str_to_exp($1.strip)
                if exp[:typing].to_uniq_str == $2.strip
                  next nil
                else
                  puts "Type Assertion failed".colorize(:red)
                  puts "Description: #{$1.strip}"
                  puts "Expected: #{$2.strip}"
                  puts "Actual:   #{exp[:typing].to_uniq_str}"
                  next :assertion_error
                end
              end
            end
            puts "Error: invalid argument for :assert-type"
            next :command_format_error
          end

          command "assert-error" do |arg|
            if arg =~ /^\s*([a-z][a-zA-Z0-9_]*)\s*=>\s*(.*)$/
              expected_error_code = $1
              res = disable_io{ process_repl_line($2) }
              if res.to_s == expected_error_code
                next nil
              else
                puts "Error-Assertion error"
                puts "Expected error-code: #{expected_error_code}"
                puts "Actual error-code: #{res}"
                next :assertion_error
              end
            else
              puts "Error: invalid argument for :assert-error"
              next :command_format_error
            end
          end

          command "replace-node" do |arg|
            if arg =~ /^\s*([a-z][a-zA-Z0-9]*)\s*=>\s*([a-z][a-zA-Z0-9]*)\s*$/
              real_n_ln, dummy_n_ln = @top[:dict][:node_space][$1], @top[:dict][:node_space][$2]
              unless real_n_ln
                puts "Error: Node `#{$1}' is undefined"
                next :replace_node_err1
              end
              unless dummy_n_ln
                puts "Error: Node `#{$2}' is undefined"
                next :replace_node_err2
              end
              unless real_n_ln.get[:typing].to_uniq_str == dummy_n_ln.get[:typing].to_uniq_str
                puts "Error: Types of Real-Node `#{$1}' and Dummy-Node `#{$2}' are different"
                puts "#{$1} : #{real_n_ln.get[:typing].to_uniq_str}"
                puts "#{$2} : #{dummy_n_ln.get[:typing].to_uniq_str}"
                next :replace_node_err3
              end
              collect_deps = proc do |node|
                if node.is_a?(NodeDef)
                  [node] + node[:params].reject{|x| x[:last]}.map{|p|
                    collect_deps.call(@top[:dict][:node_space][p[:name][:desc]].get)
                  }.flatten
                else
                  [node]
                end
              end
              c1 = collect_deps.call(dummy_n_ln.get).find{|x| x[:name] == real_n_ln.get[:name]}
              c2 = collect_deps.call(real_n_ln.get).find{|x| x[:name] == dummy_n_ln.get[:name]}
              unless c1 == nil && c2 == nil
                puts "Error: Real-Node `#{$1}' and Dummy-Node `#{$2}' are on depending relation"
                next :replace_node_err4
              end
              if real_n_ln.get[:init_exp] && !dummy_n_ln.get[:init_exp]
                puts "Error: Dummy-Node `#{$2}' should have init-exp"
                next :replace_node_err5
              end
              @node_replacement ||= {}
              @node_replacement[$1] = dummy_n_ln.get
              next nil
            else
              next :command_format_error
            end
          end

          command "compile" do
            File.open(@main_path + ".c", 'w') do |c_file|
              File.open(@main_path + ".h", 'w') do |h_file|
                C::Codegen.codegen(@top, c_file, h_file)
              end
            end
          end

          command "c" do
            Emfrp::Codegen.codegen(@top, @output_io, @output_io, "hoge")
            next nil
          end

          command "compile-dot" do |arg|
            if arg.strip != ""
              File.open(arg, "w") do |f|
                Graphviz.compile(@top, f)
              end
            else
              Graphviz.compile(@top, @output_io)
            end
          end

        end
      end
    end
  end
end
