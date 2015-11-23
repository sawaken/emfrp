require "pp"

require "emfrp/version"
require "emfrp/parser/parser"
require 'emfrp/pre_check/pre_check'
require 'emfrp/typing/typing'
require 'emfrp/c_codegen/c_codegen'
require 'emfrp/compile_error'

module Emfrp
  def self.main(main_src_path, file_loader, c_output, h_output)
    begin
      top = Parser.parse_input(main_src_path, file_loader)
      PreCheck.check(top)
      Typing.typing(top)
      #CaseCompCheck.check(top)
    rescue Parser::ParsingError => err
      err.print_error(STDERR)
      exit(1)
    rescue CompileError => err
      err.print_error(STDERR, file_loader)
      exit(1)
    end

    exit(1)

    cgen = CCodeGen.new
    cgen.gen(top)
    puts cgen.to_s

    exit
    c_code = CCodeGen.compile(top)
    c_output << c_code.cgen
    h_output << c_code.hgen
  end

  class FileLoader
    def initialize(include_dirs)
      @include_dirs = include_dirs
    end

    def loaded?(path)
      @loaded_hash ||= {}
      @loaded_hash.has_key?(path)
    end

    def get_src_from_full_path(required_full_path)
      @loaded_hash.each do |path, x|
        src_str, full_path = *x
        if full_path == required_full_path
          return src_str
        end
      end
      raise "#{required_full_path} is not found"
    end

    def load(path)
      path_str = path.is_a?(Array) ? path.join("/") : path
      @include_dirs.each do |d|
        full_path = File.expand_path(d + path_str)
        if File.exist?(full_path) && File.ftype(full_path) == "file"
          src_str = File.open(full_path, 'r'){|f| f.read}
          return @loaded_hash[path] = [src_str, full_path]
        elsif File.exist?(full_path + ".mfrp") && File.ftype(full_path + ".mfrp") == "file"
          src_str = File.open(full_path + ".mfrp", 'r'){|f| f.read}
          return @loaded_hash[path] = [src_str, full_path + ".mfrp"]
        end
      end
      raise "Cannot load #{path_str}"
    end
  end
end
