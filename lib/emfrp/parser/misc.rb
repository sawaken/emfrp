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
        SSymbol.new(
          :desc => s.map(&:item).join,
          :start_pos => s[0].tag,
          :end_pos => s[-1].tag
        )
      end
    end

    parser :ws do # -> ()
      tabspace | newline | commentout
    end

    parser :commentout do # -> ()
      char("#") > many(non_newline)
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

    parser :ident_begin_lower do # -> SSymbol
      seq(
        lower_alpha.name(:head),
        many(lower_alpha | upper_alpha | digit | char("_")).name(:tail)
      ).map do |x|
        items = [x[:head]] + x[:tail]
        SSymbol.new(
          :desc => items.map{|i| i.item}.join,
          :start_pos => items[0].tag,
          :end_pos => items[-1].tag
        )
      end
    end

    parser :ident_begin_upper do # -> SSymbol
      seq(
        upper_alpha.name(:head),
        many(lower_alpha | upper_alpha | digit | char("_")).name(:tail)
      ).map do |x|
        items = [x[:head]] + x[:tail]
        SSymbol.new(
          :desc => items.map{|i| i.item}.join,
          :start_pos => items[0].tag,
          :end_pos => items[-1].tag
        )
      end
    end

    parser :positive_integer do # -> SSymbol
      seq(
        pdigit.name(:head),
        many(digit).name(:tail)
      ).map do |x|
        items = [x[:head]] + x[:tail]
        SSymbol.new(
          :desc => items.map{|i| i.item}.join,
          :start_pos => items[0].tag,
          :end_pos => items[-1].tag
        )
      end
    end

    parser :zero_integer do # -> SSymbol
      symbol("0")
    end

    parser :digit_symbol do # -> SSymbol
      ("0".."9").map{|c| symbol(c)}.inject(&:|)
    end

    parser :cfunc_name do # -> SSymbol
      ident_begin_lower | ident_begin_upper
    end

    parser :func_name do # -> SSymbol
      ident_begin_lower
    end

    parser :data_name do # -> SSymbol
      ident_begin_lower
    end

    parser :method_name do # -> SSymbol
      operator | ident_begin_lower
    end

    parser :var_name do # -> SSymbol
      ident_begin_lower
    end

    parser :node_instance_name do # -> SSymbol
      ident_begin_lower
    end

    parser :var_name_allow_last do # -> SSymbol
      var_with_last | ident_begin_lower
    end

    parser :var_with_last do # -> SSymbol
      seq(
        ident_begin_lower.name(:prefix),
        symbol("@last").name(:suffix)
      ).map do |x|
        SSymbol.new(x.to_h, :desc => x[:prefix][:desc] + x[:suffix][:desc])
      end
    end

    OPUsable = "!#$%&*+./<=>?@\\^|-~"

    parser :operator do # -> SSymbol
      usable = OPUsable.chars.map{|c| char(c)}.inject(&:|)
      ng = ["..", ":", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>", ".", "#", "@@"]
      many1(usable) >> proc{|items|
        token = items.map{|i| i.item}.join
        if ng.include?(token)
          fail
        else
          ok(SSymbol.new(
            :desc => token,
            :start_pos => items[0].tag,
            :end_pos => items[-1].tag
          ))
        end
      }
    end

    parser :operator_general do # -> SSymbol
      operator ^ (char("`") > func_name < char("`"))
    end
  end
end
