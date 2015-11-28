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
      @read_nums = (1..1000).to_a
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
      "%03d" % @read_nums.shift
    end

    def add_line(line)
      @inputs << line
      process_inputs()
      return true
    rescue Parser::ParsingError, CompileError
      @inputs.pop
      return false
    end

    def command(com, line)
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
        if type_def = (@top[:types] + @top[:ptypes]).find{|x| x[:type][:name][:desc] == line}
          pp type_def
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
      else
        puts "Error undefined command `#{com}`"
      end
    end

    def eval_line(line)
      name = "evaldata%03d" % (@read_nums.first - 1)
      if add_line("data #{name} = #{line}")
        exp = @top[:datas].find{|x| x[:name][:desc] ==name}[:exp]
        val = eval_exp(exp)
        puts "#{value_to_s(val)} : #{exp[:typing].to_uniq_str}"
      end
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
      else
        raise "Unexpected expression type #{exp.class} (bug)"
      end
    end

    def process_inputs
      main_top = @main_module_top || @main_material_top
      src_str = (["material REPL"] + @inputs).join("\n")
      @top = parse_commandline_inputs(src_str, "command-line", @file_loader, main_top)
    end

    def parse_commandline_inputs(src_str, file_name, file_loader, main_top)
      file_loader.add_to_loaded(file_name, src_str)
      top = Parser.parse_src(src_str, file_name, file_loader, Parser.material_file, main_top)
      PreCheck.check(top)
      Typing.typing(top)
      Convert.convert(top)
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
