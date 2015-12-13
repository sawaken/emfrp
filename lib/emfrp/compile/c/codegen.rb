
module Emfrp
  module Codegen
    extend self

    def codegen(top, c_output, h_output)
      Monofy.monofy(top)
      ct = CodegenContext.nex(top)
      Top.codegen(ct)
      ct.code_generate(c_output, h_output)
    end
  end
end
