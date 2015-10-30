module Emfrp
  class Parser

    # Utils & Commons
    # --------------------

    SPChar = {
      :space => "\s",
      :tab => "\t",
      :newline => "\n",
      :doublequote => "\"",
      :singlequote => "'",
      :backslash => "\\",
    }
    SPChar.each do |name, c|
      parser(name){char(c)}
      parser("non_#{name}".to_sym){notchar(c)}
    end

    parser :key do |keyword| # -> Hash
      str(keyword).map do |is|
        is[0].tag
      end
    end

    parser :symbol do |s|
      str(s).map do |s|
        Symbol.new(:desc => s.map(&:item).join, :tag => s[0].tag)
      end
    end

    parser :ws do # -> ()
      tabspace | newline
    end

    parser :newline do #-> ()
      char("\n")
    end

    parser :tabspace do # -> ()
      char("\s") | char("\t")
    end

    parser :comma_separator do # -> ()
      many(ws) > str(",") > many(ws)
    end

    parser :or_separator do # -> ()
      many(ws) > str("|") > many(ws)
    end

    parser :end_of_def do # -> ()
      many(tabspace) > newline > many(ws)
    end

    parser :ident_begin_lower do # -> Symbol
      seq(lower_alpha, many(lower_alpha | upper_alpha | digit | char("_"))).map do |xs|
        items = [xs[0]] + xs[1]
        Symbol.new(:desc => items.map{|i| i.item}.join, :tag => xs[0].tag)
      end
    end

    parser :ident_begin_upper do # -> Symbol
      seq(upper_alpha, many(lower_alpha | upper_alpha | digit | char("_"))).map do |xs|
        items = [xs[0]] + xs[1]
        Symbol.new(:desc => items.map{|i| i.item}.join, :tag => xs[0].tag)
      end
    end

    parser :positive_integer do # -> Symbol
      seq(pdigit, many(digit)).map do |x|
        Symbol.new(:desc => ([x[0]] + x[1]).map{|i| i.item}.join.to_s, :tag => x[0].tag)
      end
    end

    parser :cfunc_name do # -> Symbol
      ident_begin_lower | ident_begin_upper
    end

    parser :func_name do # -> Symbol
      ident_begin_lower
    end

    parser :data_name do # -> Symbol
      ident_begin_lower
    end

    parser :method_name do # -> Symbol
      operator | ident_begin_lower
    end

    parser :var_name do # -> Symbol
      ident_begin_lower
    end

    parser :node_instance_name do # -> Symbol
      ident_begin_lower
    end

    parser :var_name_allow_last do # -> Symbol
      (ident_begin_lower < str("@last")).map{|s| s.update(:desc => s[:desc] + "@last")} | ident_begin_lower
    end

    parser :operator do # -> Symbol
      usable = "!#$%&*+./<=>?@\\^|-~".chars.map{|c| char(c)}.inject(&:|)
      ng = ["..", ":", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>", "."]
      many1(usable) >> proc{|cs|
        token = cs.map{|i| i.item}.join
        if ng.include?(token)
          fail
        else
          ok(Symbol.new(:desc => token, :tag => cs[0].tag))
        end
      }
    end
  end
end
