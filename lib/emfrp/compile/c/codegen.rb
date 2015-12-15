require 'emfrp/compile/c/monofy'
require 'emfrp/compile/c/alloc'
require 'emfrp/compile/c/codegen_context'
require 'emfrp/compile/c/syntax_codegen'

module Emfrp
  module Codegen
    extend self

    def codegen(top, c_output, h_output, main_output, name)
      Monofy.monofy(top)
      ct = CodegenContext.new(top)
      ar = AllocRequirement.new(top)
      top.codegen(ct, ar)
      ct.code_generate(c_output, h_output, main_output, name)
    end
  end
end
