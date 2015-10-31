require "emfrp/version"

module Emfrp
  def self.main(inputs, c_output, h_output)
    begin
      toplevel = Parser.parse_all(inputs)
      SyntaxCheck.check_all(toplevel)
      Typing.typing(toplevel)
      CaseCompCheck.check(toplevel)
    rescue => err
      raise err
    end
    c_code = Compile.compile(toplevel)
    c_output << c_code.cgen
    h_output << c_code.hgen
  end
end
