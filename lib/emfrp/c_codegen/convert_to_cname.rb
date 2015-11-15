module Emfrp
  class CCodeGen
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
      "\\" => "_backslash_",
      "^" => "_caret_",
      "|" => "_vertial_",
      "-" => "_minus_",
      "~" => "_tilde_"
    }
    def name2cname(name)
      rexp = Regexp.new("[" + Regexp.escape(SymbolToStr.keys.join) + "]")
      name.gsub(rexp, SymbolToStr)
    end
  end
end
