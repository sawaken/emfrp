require "emfrp/version"

module Emfrp
  def self.main(inputs, c_output, h_output)
    begin
      top = Parser.parse_all(inputs)
      PreCheck.check(top)
      Typing.typing(top)
      CaseCompCheck.check(top)
    rescue => err
      raise err
    end
    c_code = CCodeGen.compile(top)
    c_output << c_code.cgen
    h_output << c_code.hgen
  end
end
