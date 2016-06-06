require 'emfrp/pre_convert/make_name_dict'
require 'emfrp/pre_convert/alpha_convert'
require 'emfrp/pre_convert/node_check'

module Emfrp
  module PreConvert
    extend self

    PreConvertError = Class.new(CompileError)

    def convert(top)
      MakeNameDict.make_name_dict(top)
      AlphaConvert.alpha_convert(top, top)
      NodeCheck.node_check(top)
      #FuncCheck - check-circular-def
      #TypeCheck - check-circular-def
    end

    def additional_convert(top, definition)
      MakeNameDict.set_dict(top[:dict], definition)
      AlphaConvert.alpha_convert(top, definition)
    end

    def cancel(top, definition)
      MakeNameDict.remove_dict(top[:dict], definition)
    end

    def err(code, msg, *facts)
      raise PreConvertError.new(msg, code, *facts)
    end
  end
end
