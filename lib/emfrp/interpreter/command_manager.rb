require 'emfrp/compile/graphviz/graphviz'

module Emfrp
  class Interpreter
    class CommandManager
      def initialize(interpreter, &proc)
        @interpreter = interpreter
        @command_names = []
        @command_tbl = {}
        @command_desc_tbl = {}
        @command_usage_tbl = {}
        @command_example_tbl = {}
        @command_desc_buf = []
        @command_usage_buf = []
        @command_example_buf = []
        instance_exec(&proc)
      end

      def command(*names, &proc)
        names.each do |name|
          @command_names << ":" + name
          @command_tbl[name] = proc
          @command_desc_tbl[name] = @command_desc_buf
          @command_usage_tbl[name] = @command_usage_buf
          @command_example_tbl[name] = @command_example_buf
          @command_desc_buf, @command_usage_buf, @command_example_buf = [], [], []
        end
      end

      def desc(str)
        @command_desc_buf << str
      end

      def usage(str)
        @command_usage_buf << str
      end

      def example(str)
        @command_example_buf << str
      end

      def print_usage(command_name, output_io)
        if @command_tbl[command_name]
          output_io.puts ":#{command_name}".colorize(:light_blue)
          output_io.puts @command_desc_tbl[command_name].map{|x| "  " + x}.join("\n")
          if @command_usage_tbl[command_name].size > 0
            output_io.puts "  Usage:".colorize(:green)
            output_io.puts @command_usage_tbl[command_name].map{|x| "    " + x}.join("\n")
          end
          if @command_example_tbl[command_name].size > 0
            output_io.puts "  Example:".colorize(:green)
            output_io.puts @command_example_tbl[command_name].map{|x| "    " + x}.join("\n")
          end
          return nil
        else
          return :command_not_found
        end
      end

      def print_all_usages(output_io)
        @command_tbl.keys.sort.each do |name|
          print_usage(name, output_io)
        end
        return nil
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

          desc "Showing object type by specifying it's name."
          example "data x = 1"
          example ":t x"
          command "t" do |arg|
            name = arg.strip
            if f = @top[:dict][:func_space][name]
              puts "func #{name} : " + f.get[:params].map{|x| x[:typing].inspect}.join(", ") +
              " -> " + f.get[:typing].inspect
            end
            if d = @top[:dict][:data_space][name]
              puts "data #{name} : " + d.get[:typing].inspect
            end
            if t = @top[:dict][:type_space][name]
              case t.get
              when TypeDef
                puts "Type #{name} : " + t.get[:tvalues][0][:typing].inspect
              when PrimTypeDef
                puts "PrimType #{name} : " + name
              end
            end
            if c = @top[:dict][:const_space][name]
              puts "constructor #{name} : " + c.get[:params].map{|x| x[:typing].inspect}.join(", ") +
              " -> " + c.get[:typing].inspect
            end
            if n = @top[:dict][:node_space][name]
              puts "node #{name} : " + n.get[:typing].inspect
            end
            next nil
          end

          desc "Showing internal AST by specifying element's name."
          command "ast" do |arg|
            name = arg.strip
            if f = @top[:dict][:func_space][name]
              pp f.get
            elsif d = @top[:dict][:data_space][name]
              pp d.get
            elsif t = @top[:dict][:type_space][name]
              pp t.get
            elsif c = @top[:dict][:const_space][name]
              pp c.get
            elsif n = @top[:dict][:node_space][name]
              pp n.get
            elsif name == "top"
              pp @top
            elsif name == "ifuncs"
              pp @top[:dict][:ifuncs_space].keys
            elsif name == "itypes"
              pp @top[:dict][:itypes_space].keys
            else
              puts "Error: `#{name}' is not found"
              next :target_not_found
            end
            next nil
          end

          desc "Testing two expression's equality."
          usage ":assert-equals <expected-exp>, <testing-exp>"
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
              :command_format_error
            end
          end

          desc "Executing all commands embedded on source-files."
          command "exec-embedded-commands" do
            exec_embedded_commands()
          end

          desc "Define documentation about function. (in preparation)"
          command "set-func-doc" do |arg|
            nil
          end

          desc "Testing node as function."
          usage ":assert-node <node-name> <input-exp>* => <expected-output-exp>"
          example ":assert-node mynode 1, 2 => 3"
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
                    next :assert_node_error1
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
                  next :assert_node_error2
                end
              else
                puts "Error: invalid node name #{$1}"
                next :assert_node_error3
              end
            else
              next :command_format_error
            end
          end

          desc "Testing whole-module by feeding inputs."
          usage ":assert-module <input-exp>* => <expected-ouput-exp>*"
          example ":assert-module 1, 2 => 2, 4"
          command "assert-module" do |arg|
            if arg =~ /^(.*)=>(.*)$/
              input_types = ["Unit", "Unit"] + @top[:inputs].map{|x| x[:typing].to_uniq_str}
              exp_str = ($1.strip == "" ? "(Unit, Unit)" : "(Unit, Unit, #{$1.strip})")
              input_exps = str_to_exp(exp_str, "(#{input_types.join(", ")})")
              output_types = @top[:outputs].map{|x| x[:typing].to_uniq_str}
              output_exps = str_to_exp("(Unit, #{$2})", "(Unit, #{output_types.join(", ")})")
              if input_exps == nil || output_exps == nil
                puts "Error: invalid expression"
                next :assert_module_error1
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
              :command_format_error
            end
          end

          desc "Testing expression's type."
          usage ":assert-type: <exp> => <type>"
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
            next :command_format_error
          end

          desc "Testing that specified command finishes with specified error-code"
          usage ":assert-error <expected-error-code> => <testing-command>"
          example ":assert-error assertion_error => :assert-type 1 => Double"
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
              next :command_format_error
            end
          end

          desc "Replace one node to another like Stab."
          desc "currently, this is only for testing (command-line assertion)."
          usage ":replace-node <replaced-node-name> => <alternative-node-name>"
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

          desc "Compiling module-file into c-program code."
          desc "Target file-name is currently fixed..."
          desc "(module-name is used and files are dumped on current-dir)"
          usage ":compile"
          command "compile" do
            next compile_default()
          end

          desc "Compiling module-file into graphviz-source code (.dot file)."
          desc "If file-name is given as a command-argument, the code is output to it."
          desc "Otherwise, the code is output on console."
          example ":compile-dot graph.dot"
          command "compile-dot" do |arg|
            if arg.strip != ""
              File.open(arg, "w") do |f|
                Graphviz.compile(@top, f)
              end
            else
              Graphviz.compile(@top, @output_io)
            end
          end

          desc "Showing usage of all commands."
          command "commands" do
            @command_manager.print_all_usages(@output_io)
          end

        end
      end
    end
  end
end
