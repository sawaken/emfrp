module Emfrp
  module CCodeGen
    SymbolToStr = {
      "!" => "_exclamation_",
      "#" => "_hash_",
      "$" => "_dollar_",
      "%" => "_parcent_",
      "&" => "_anpersand",
      "*" => "_asterisk_",
      "+" => "_plus_",
      "." => "_dot_",
      "/" => "_slash_",
      "<" => "_lt_",
      "=" => "_eq_",
      ">" => "_gt_",
      "?" => "_question_",
      "@" => "_at_",
      "¥¥" => "_backslash_",
      "^" => "_caret_",
      "|" => "_vertial_",
      "-" => "_minus_",
      "~" => "_tilde_"
    }
    def name2cname(name)
      name.gsub(/./, SymbolToStr)
    end

    def type2cname(utype)
      if utype.var?
        raise "argument error"
      end
      if utype.typeargs.size == 0
        utype.typename.to_s
      else
        utype.typename.to_s + "_begin_" + utype.typeargs.map{|x| type2name(x)}.join("_and_") + "_end_"
      end
    end
  end
end
