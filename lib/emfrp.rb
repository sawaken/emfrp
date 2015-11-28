require "pp"

require "emfrp/version"
require "emfrp/parser/parser"
require 'emfrp/pre_check/pre_check'
require 'emfrp/typing/typing'
require 'emfrp/c_codegen/c_codegen'
require 'emfrp/compile_error'
require 'emfrp/file_loader'
require 'emfrp/convert/convert'

module Emfrp
  def self.main(main_src_path, file_loader, c_output, h_output)
    begin
      top = Parser.parse_input(main_src_path, file_loader)
      PreCheck.check(top)
      Typing.typing(top)
      Convert.convert(top)
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
end
