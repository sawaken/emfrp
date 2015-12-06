require 'pp'
require 'emfrp/file_loader'
require "emfrp/parser/parser"
require 'emfrp/pre_convert/pre_convert'
require 'emfrp/typing/typing'
require 'emfrp/convert/convert'
require 'emfrp/compile_error'
require 'emfrp/interpreter/evaluater'
require 'emfrp/interpreter/command_manager'

module Emfrp
  InterpreterError = Class.new(StandardError)

  class Interpreter
    def initialize(include_dirs, output_io, main_path)
      @file_loader = FileLoader.new(include_dirs)
      @main_path = main_path
      @output_io = output_io
      @readline_nums = (1..1000).to_a
      @command_manager = CommandManager.make(self)
      @top = Parser.parse_input(main_path, @file_loader, Parser.module_or_material_file)
      @infix_parser = Parser.from_infixes_to_parser(@top[:infixes])
      @top = Parser.infix_convert(@top, @infix_parser)
      PreConvert.convert(@top)
      Typing.typing(@top)
    rescue Parser::ParsingError => err
      err.print_error(@output_io)
      raise InterpreterError.new
    rescue CompileError => err
      err.print_error(@output_io, @file_loader)
      raise InterpreterError.new
    end

    def compile(c_output_io, h_output_io, print_log=false)

    end

    def append_def(uniq_id, def_str)
      file_name = "command-line-#{uniq_id}"
      @file_loader.add_to_loaded(file_name, def_str)
      d = Parser.parse(def_str, file_name, Parser.oneline_file)
      d = Parser.infix_convert(d, @infix_parser)
      PreConvert.additional_convert(@top, d)
      Typing.additional_typing(@top, d)
      @top.add(d)
      return true
    rescue Parser::ParsingError => err
      err.print_error(@output_io)
      return false
    rescue CompileError => err
      err.print_error(@output_io, @file_loader)
      PreConvert.cancel(@top, d)
      return false
    end

    def str_to_exp(exp_str, type=nil)
      @eval_serial ||= (0..1000).to_a
      uname = "tmp%03d" % @eval_serial.shift
      type_ano = type ? " : #{type}" : ""
      if append_def(uname, "data #{uname}#{type_ano} = #{exp_str}")
        @top[:datas].last[:exp]
      else
        nil
      end
    end

    def exec_embeded_commands(only_on_main_path=false)
      @top[:commands].all? do |com|
        if !only_on_main_path || com[:file_name] == @file_loader.loaded_full_path(@main_path)
          if process_repl_line(com[:command_str])
            true
          else
            puts "Embeded command on #{com[:file_name]}:#{com[:line_number]}\n"
            false
          end
        else
          true
        end
      end
    end

    def process_repl_line(line)
      readline_id = proceed_readline_id()
      case line
      when /^\s*(data|func|type)\s(.*)$/
        append_def(readline_id, line)
      when /^[a-z][a-zA-Z0-9]*\s*=(.*)$/
        append_def(readline_id, "data #{line}")
      when /^\s*\:([a-z\-]+)\s*(.*)$/
        @last_command = $1
        @command_manager.exec($1, $2, readline_id)
      when /^\s*\:\s+(.*)$/
        if @last_command
          @command_manager.exec(@last_command, $1, readline_id)
        else
          puts "Error: there isn't a last-executed command"
          false
        end
      when ""
        true
      else
        if exp = str_to_exp(line)
          val = Evaluater.eval_exp(@top, exp)
          puts "#{Evaluater.value_to_s(val)} : #{exp[:typing].inspect.colorize(:green)}"
          return true
        else
          return false
        end
      end
    end

    def close
      puts ""
    end

    def proceed_readline_id
      "%03d" % @readline_nums.shift
    end

    def current_readline_id
      "%03d" % @readline_nums.first
    end

    def completion_proc
      command_comp = @command_manager.completion_proc
      proc do |s|
        command_candidates = command_comp.call(s)
      end
    end

    def pp(obj)
      PP.pp(obj, @output_io)
    end

    def puts(str)
      @output_io.puts(str)
    end
  end
end
