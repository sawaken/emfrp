require 'pp'
require 'stringio'

require 'emfrp'
require 'emfrp/interpreter/file_loader'
require 'emfrp/interpreter/evaluater'
require 'emfrp/interpreter/command_manager'

module Emfrp
  class Interpreter
    class InterpreterError < StandardError
      attr_reader :code
      def initialize(code)
        @code = code
      end
    end

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
      raise InterpreterError.new(err.code)
    rescue CompileError => err
      err.print_error(@output_io, @file_loader)
      raise InterpreterError.new(err.code)
    end

    def compile(c_output_io, h_output_io, main_output_io, name, print_log=false)
      Emfrp::Codegen.codegen(@top, c_output_io, h_output_io, main_output_io, name)
    end

    def append_def(uniq_id, def_str)
      file_name = "command-line-#{uniq_id}"
      @file_loader.add_to_loaded(file_name, def_str)
      ds = Parser.parse(def_str, file_name, Parser.oneline_file)
      ds.map!{|d| Parser.infix_convert(d, @infix_parser)}
      ds.each do |d|
        PreConvert.additional_convert(@top, d)
        Typing.additional_typing(@top, d)
        @top.add(d)
      end
      return nil
    rescue Parser::ParsingError => err
      err.print_error(@output_io)
      return err.code
    rescue CompileError => err
      err.print_error(@output_io, @file_loader)
      ds.each do |d|
        PreConvert.cancel(@top, d)
      end
      return err.code
    end

    #-> parsed-expression or nil(fail)
    def str_to_exp(exp_str, type=nil)
      @eval_serial ||= (0..1000).to_a
      uname = "tmp%03d" % @eval_serial.shift
      type_ano = type ? " : #{type}" : ""
      unless append_def(uname, "data #{uname}#{type_ano} = #{exp_str}")
        @top[:datas].last[:exp]
      else
        nil
      end
    end

    #-> true-like(abnormal-term) / false-like(normal-term)
    def exec_embeded_commands(only_on_main_path=false) #
      @top[:commands].any? do |com|
        if !only_on_main_path || com[:file_name] == @file_loader.loaded_full_path(@main_path)
          unless process_repl_line(com[:command_str])
            nil
          else
            puts "Embeded command on #{com[:file_name]}:#{com[:line_number]}\n"
            true
          end
        else
          nil
        end
      end
    end

    #-> true-like(abnormal-term) / false-like(normal-term)
    def process_repl_line(line)
      readline_id = proceed_readline_id()
      @last_status = case line
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
          :recall_last_executed_error
        end
      when ""
        nil
      else
        if exp = str_to_exp(line)
          val = Evaluater.eval_exp(@top, exp)
          puts "#{Evaluater.value_to_s(val)} : #{exp[:typing].inspect.colorize(:green)}"
          nil
        else
          :eval_error
        end
      end
    end

    def disable_io(&block)
      output_io = @output_io
      @output_io = StringIO.new
      block.call
    ensure
      @output_io = output_io
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
        token_candidates = lexical_tokens.select{|x| x.index(s) == 0}
        command_candidates = command_comp.call(s)
        token_candidates + command_candidates
      end
    end

    def lexical_tokens
      res = []
      res += @top[:dict][:const_space].keys
      res += @top[:dict][:data_space].keys
      res += @top[:dict][:func_space].keys
      return res
    end

    def pp(obj)
      PP.pp(obj, @output_io)
    end

    def puts(str)
      @output_io.puts(str)
    end
  end
end
