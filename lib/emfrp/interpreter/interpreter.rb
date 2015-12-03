require 'emfrp/file_loader'
require "emfrp/parser/parser"
require 'emfrp/pre_check/pre_check'
require 'emfrp/typing/typing'
require 'emfrp/convert/convert'
require 'emfrp/compile_error'

require 'pp'

module Emfrp
  class Interpreter
    def initialize(include_dirs, output_io, main_path)
      @include_dirs = include_dirs
      @output_io = output_io
      @inputs = []
      begin
        @file_loader = FileLoader.new(@include_dirs)
        @main_module_top = Parser.parse_input(main_path, @file_loader, Parser.module_file)
      rescue Parser::ParsingError
        @file_loader = FileLoader.new(@include_dirs)
        @main_material_top = Parser.parse_input(main_path, @file_loader, Parser.material_file)
      end
      add_line("")
    end

    def pp(obj)
      PP.pp(obj, @output_io)
    end

    def puts(str)
      @output_io.puts(str)
    end

    def read_num
      @read_nums ||= (1..1000).to_a
      "%03d" % @read_nums.shift
    end

    def end_of_input
      puts ""
    end

    def process_command(command_str) # -> true(ok) / false(fail)
      if Parser.exp?(command_str, "command-line")
        eval_line(command_str)
      elsif command_str =~ /^\s*\:([a-z\-]+)\s*(.*)$/
        command($1, $2)
      else
        add_line(command_str)
      end
    end

    def add_line(line) # -> true(ok) / false(fail)
      @inputs << line
      process_inputs()
      return true
    rescue Parser::ParsingError, CompileError
      @inputs.pop
      return false
    end

    def command(com, line) # -> true(ok) / false(fail)
      process_inputs() unless @top
      case com
      when "type-f", "ast-f"
        if func_def = (@top[:funcs] + @top[:pfuncs]).find{|x| x[:name][:desc] == line}
          case com
          when "type-f"
            puts "#{line} : " + func_def[:typing].to_uniq_str
          when "ast-f"
            pp func_def
          end
        else
          puts "Error: undefined function `#{line}`"
        end
      when "type", "ast"
        if data_def = @top[:datas].find{|x| x[:name][:desc] == line}
          case com
          when "type"
            puts "#{line} : " + data_def[:typing].to_uniq_str
          when "ast"
            pp data_def
          end
        else
          puts "Error: undefined data `#{line}`"
        end
      when "ast-t"
        type_def = @top[:types].find{|x| x[:type][:name][:desc] == line}
        ptype_def = @top[:ptypes].find{|x| x[:name][:desc] == line}
        if type_def || ptype_def
          pp type_def || ptype_def
        else
          puts "Error: undefined type `#{line}`"
        end
      when "ast-n", "type-n"
        if node_def = (@top[:nodes] + @top[:inputs]).find{|x| x[:name][:desc] == line}
          case com
          when "type-n"
            puts "#{line} : " + node_def[:typing].to_uniq_str
          when "ast-n"
            pp node_def
          end
        else
          puts "Error: undefined node/input `#{line}`"
        end
      when "ast-top"
        pp @top
      when "ast-ifuncs"
        pp @top[:ifuncs]
      when "ast-itypes"
        pp @top[:itypes]
      when "enable-convert"
        @enable_convert = true
        add_line("")
        puts "ok."
      when "assert-equal"
        res = Parser.exps?(line + "\n", "command-line")
        if res && res.size == 2 && evaluated = eval_exp_str("(#{line})")
          v1, v2 = evaluated[0][1], evaluated[0][2]
          if v1 != v2
            puts "Expected: #{value_to_s(v1)}"
            puts "Real: #{value_to_s(v2)}"
            return false
          end
        else
          puts "Error: invalid argument for assert-equal"
        end
      else
        puts "Error undefined command `#{com}`"
      end
      return true
    end

    def eval_line(line) # -> true(ok) / false(fail)
      if res = eval_exp_str(line)
        v, e = *res
        puts "#{value_to_s(v)} : #{e[:typing].to_uniq_str}"
        return true
      else
        return false
      end
    end

    def eval_exp_str(exp_str)
      @evaldata_serial ||= (0..1000).to_a
      name = "evaldata%03d" % @evaldata_serial.shift
      if add_line("data #{name} = #{exp_str}")
        exp = @top[:datas].find{|x| x[:name][:desc] == name}[:exp]
        return [eval_exp(exp), exp]
      end
      return false
    end

    def value_to_s(val)
      if val.is_a?(Array) && val.first.is_a?(Symbol)
        "#{val.first}" + (val.size > 1 ? "(#{val.drop(1).map{|x| value_to_s(x)}.join(", ")})" : "")
      else
        val.to_s
      end
    end

    def eval_exp(exp, env={})
      case exp
      when FuncCall
        case f = exp[:func].get
        when PrimFuncDef
          if ruby_exp = f[:foreigns].find{|x| x[:language][:desc] == "ruby"}
            proc_str = "proc{|#{f[:params].map{|x| x[:name][:desc]}.join(",")}| #{ruby_exp[:desc]}}"
            eval(proc_str).call(*exp[:args].map{|e| eval_exp(e, env)})
          else
            raise "Primitive Function `#{f[:name][:desc]}` is not defined for ruby"
          end
        when FuncDef
          f[:params].map{|param| [param[:name], Link.new(f)]}.zip(exp[:args]).each do |key, arg|
            env[key] = eval_exp(arg, env)
          end
          eval_exp(f[:exp], env)
        end
      when ValueConst
        [exp[:name][:desc].to_sym] + exp[:args].map{|e| eval_exp(e, env)}
      when LiteralIntegral
        exp[:entity][:desc].to_i
      when LiteralChar
        exp[:entity].ord
      when LiteralFloating
        exp[:entity][:desc].to_f
      when VarRef
        key = [exp[:name], exp[:binder]]
        if exp[:binder].get.is_a?(DataDef) && !env[key]
          env[key] = eval_exp(exp[:binder].get[:exp], env)
        end
        env[key]
      when MatchExp
        left_val = eval_exp(exp[:exp], env)
        exp[:cases].each do |c|
          if match_result = pattern_match(c, left_val)
            return eval_exp(c[:exp], env.merge(match_result))
          end
        end
        raise "pattern match fail"
      else
        raise "Unexpected expression type #{exp.class} (bug)"
      end
    end

    def pattern_match(c, v, pattern=c[:pattern], vars={})
      if pattern[:ref]
        key = [pattern[:ref], Link.new(c)]
        vars[key] = v
      end
      case pattern
      when ValuePattern
        if v.is_a?(Array) && pattern[:name][:desc].to_sym == v[0]
          res = v.drop(1).zip(pattern[:args]).all? do |ch_v, ch_p|
            pattern_match(c, ch_v, ch_p, vars)
          end
          return vars if res
        end
      when IntegralPattern
        if v.is_a?(Integer) && pattern[:val][:entity][:desc].to_i == v
          return vars
        end
      when AnyPattern
        return vars
      end
      return nil
    end

    def process_inputs
      main_top = @main_module_top || @main_material_top
      src_str = (["material REPL"] + @inputs).join("\n")
      @top = parse_commandline_inputs(src_str, "command-line", @file_loader, main_top)
      unless @at_first
        @at_first = true
        ress = @top[:commands].reject{|com| process_command(com[:command_str])}
        puts "#{ress.size} erros occurred." if ress.size > 0
      end
    end

    def parse_commandline_inputs(src_str, file_name, file_loader, main_top)
      file_loader.add_to_loaded(file_name, src_str)
      top = Parser.parse_src(src_str, file_name, file_loader, Parser.material_file, main_top)
      PreCheck.check(top)
      Typing.typing(top)
      Convert.convert(top) if @enable_convert
      return top
    rescue Parser::ParsingError => err
      err.print_error(@output_io)
      raise err
    rescue CompileError => err
      err.print_error(@output_io, file_loader)
      raise err
    end
  end
end
