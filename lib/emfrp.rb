require "pp"

require "emfrp/version"
require "emfrp/parser/parser"
require 'emfrp/pre_check/pre_check'
require 'emfrp/typing/typing'
require 'emfrp/c_codegen/c_codegen'
require 'emfrp/compile_error'

module Emfrp
  def self.main(src_strs, file_names, c_output, h_output)
    begin
      top = Parser.parse_inputs(src_strs, file_names)
      PreCheck.check(top)
      Typing.typing(top)
      #CaseCompCheck.check(top)
    rescue Parser::ParsingError => err
      err.print_error(STDERR)
      exit(1)
    rescue CompileError => err
      err.print_error(STDERR, src_strs, file_names)
      exit(1)
    end
    cgen = CCodeGen.new
    cgen.gen(top)
    puts cgen.to_s

    exit
    c_code = CCodeGen.compile(top)
    c_output << c_code.cgen
    h_output << c_code.hgen
  end
end
