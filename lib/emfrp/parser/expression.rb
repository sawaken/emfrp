require 'parser_combinator/string_parser'

module Emfrp
  class Parser < ParserCombinator::StringParser

    # Expression
    # --------------------

    parser :exp do
      if_exp ^ builtin_operation
    end

    # Builtin Operator Expression
    # --------------------

    parser :if_exp do
      seq(
        key("if").name(:tag),
        many1(ws),
        exp.err("if-exp", "valid conditional exp").name(:cond),
        many1(ws),
        str("then"),
        many1(ws),
        exp.err("if-exp", "valid then exp").name(:then),
        many1(ws),
        str("else"),
        many1(ws),
        exp.err("if-exp", "valid then exp").name(:else),
      ).map do |x|
        IfExp.new(x.to_h)
      end
    end

    parser :builtin_operation do
      x = match_with_group_case_op ^ match_with_single_case_op
      seq(
        operator_exp.name(:exp),
        many_fail(many1(ws) > x).name(:builtin_ops)
      ).map do |x|
        x[:builtin_ops].inject(x[:exp]) do |acc, ep|
          ep.call(acc)
        end
      end
    end

    parser :match_with_group_case_op do
      seq(
        key("match:").name(:tag),
        many(ws),
        case_group.err("match-exp", "valid case statement").name(:cases)
      ).map do |x|
        proc{|e| MatchExp.new(x.to_h, :exp => e)}
      end
    end

    parser :match_with_single_case_op do
      seq(
        key("match").name(:tag),
        many1(ws),
        pattern.err("match-exp", "invalid single-case").name(:pattern),
        many1(ws),
        str("to"),
        many1(ws),
        exp.err("match-exp", "invalid exp").name(:exp)
      ).map do |x|
        c = Case.new(:tag => x[:tag], :pattern => x[:pattern], :exp => x[:exp])
        proc{|e| MatchExp.new(:tag => x[:tag], :cases => [c], :exp => e)}
      end
    end

    parser :case_group do
      c = seq(
        key("case").name(:tag),
        many1(ws),
        pattern.err("case-statement", "invalid pattern of case").name(:pattern),
        many1(ws),
        str("to").err("caase-statement", "'to'"),
        many1(ws),
        exp.err("match-exp", "invalid exp").name(:exp)
      ).map{|x| Case.new(x.to_h)}
      many1_fail(c, many1(ws)) < many1(ws) < str(":endcase")
    end

    parser :pattern do
      dont_care_pattern ^ name_pattern ^ recursive_pattern ^ no_arg_pattern ^ tuple_pattern ^ int_pattern
    end

    parser :dont_care_pattern do
      char("_").map do |c|
        AnyPattern.new(:tag => c.tag, :ref => nil)
      end
    end

    parser :name_pattern do
      ident_begin_lower.map do |n|
        AnyPattern.new(:tag => n[:tag], :ref => n)
      end
    end

    parser :recursive_pattern do
      seq(
        tvalue_symbol.name(:sym),
        many(ws),
        str("("),
        many(ws),
        many1_fail(pattern, comma_separator).err("pattern", "invalide pattern").name(:args),
        many(ws),
        str(")"),
        opt_fail(many(ws) > str("as") > many1(ws) > var_name.err("pattern", "invalid name")).map{|x| x[0]}.name(:ref)
      ).map{|x| ValuePattern.new(x.to_h, :tag => x[0][:tag])}
    end

    parser :no_arg_pattern do
      seq(
        tvalue_symbol.name(:sym),
        opt_fail(many1(ws) > str("as") > var_name.err("pattern", "invalid name")).map{|x| x[0]}.name(:ref)
      ).map{|x| ValuePattern.new(x.to_h, :args => [], :tag => x[0][:tag])}
    end

    parser :tuple_pattern do
      seq(
        key("(").name(:tag),
        many(ws),
        pattern.err("tuple-pattern", "invalid child pattern").name(:arg_head),
        many(ws),
        str(",").err("tuple-pattern", "invalid child pattern"),
        many(ws),
        many1_fail(pattern, comma_separator).err("tuple-pattern", "invalid child pattern").name(:arg_tail),
        many(ws),
        str(")"),
        opt_fail(
          many(ws) > str("as") > many1(ws) > var_name.err("tuple-pattern", "invalid name")
        ).map{|x| x[0]}.name(:ref)
      ).map do |x|
        args = [x[:arg_head]] + x[:arg_tail]
        TuplePattern.new(:tag => x[:tag], :args => args, :ref => x[:ref])
      end
    end

    parser :int_pattern do
      int_literal.map{|n| IntPattern.new(:val => n)}
    end

    # Operator Expression
    # --------------------

    parser :operator_exp do
      operator_app = operator ^ (char("`") > func_name < char("`"))
      opexp = operator_app.map do |op|
        proc do |l, r|
          if l.is_a?(OperatorSeq)
            OperatorSeq.new(:seq => l[:seq] + [op, r], :tag => l[:tag])
          else
            OperatorSeq.new(:seq => [l, op, r], :tag => l[:tag])
          end
        end
      end
      binopl_fail(primary, many(ws) > opexp < many(ws))
    end

    # Lower Expression
    # --------------------

    parser :primary do
      atom >> proc{|a|
        many(many(ws) > method_call).map do |cs|
          if cs == [] then a else cs.inject(a){|acc, p| p.call(acc)} end
        end
      }
    end

    parser :method_call do
      seq(
        key(".").name(:tag),
        many(ws),
        ident_begin_lower.err("method_call", "invalid method name").name(:method_name),
        opt_fail(many(ws) > str("(") > many(ws) > many_fail(exp, comma_separator) < many(ws) < str(")") < many(ws))
          .map{|x| x.flatten}.err("method_call", "invalid form of argument").name(:args)
      ).map do |x|
        proc{|receiver| MethodCall.new(x.to_h, :receiver => receiver)}
      end
    end

    parser :atom do
      literal_exp ^ single_op ^ func_call ^ block_exp ^ array_cons ^ gf_cons ^ value_cons ^ skip ^ var_ref
    end

    parser :single_op do
      seq(operator, many(ws), atom).map do |x|
        UnaryOperatorExp.new(:tag => x[0][:tag], :op => x[0], :exp => x[2])
      end
    end

    parser :func_call do
      seq(
        func_name.name(:func_name),
        many(ws) > str("(") > many(ws),
        many1_fail(exp, comma_separator).name(:args),
        many(ws) > str(")")
      ).map do |x|
        FuncCall.new(x.to_h, :tag => x[0][:tag])
      end
    end

    parser :block_exp do
      seq(
        key("{").name(:tag),
        many(ws),
        many_fail(many(ws) > assign).name(:assigns),
        many(ws),
        str("=>").err("block-exp", "'=>'"),
        many(ws),
        exp.err("block-exp", "valid return-exp").name(:exp),
        many(ws),
        str("}"),
      ).map do |x|
        BlockExp.new(x.to_h)
      end
    end

    parser :assign do
      seq(
        var_name.name(:var_name),
        many(ws),
        str("="),
        many(ws),
        exp.err("assign", "invalid assign statement").name(:exp)
      ).map do |x|
        Assign.new(x.to_h, :tag => x[0][:tag])
      end
    end

    parser :parenth_exp do
      str("(") > many(ws) > exp < many(ws) < str(")")
    end

    parser :value_cons do # -> ValueConst
      seq(
        tvalue_symbol.name(:tvalue_name),
        opt_fail(many(ws) > str("(") > many(ws) > many_fail(exp, comma_separator) < many(ws) < str(")") < many(ws))
          .map{|x| x.flatten}.err("value-construction", "invalid form of argument").name(:args)
      ).map do |x|
        ValueConst.new(x.to_h, :tag => x[0][:tag])
      end
    end

    parser :array_cons do # -> ArrayConst
      seq(
        key("Array").name(:tag),
        str("<").err("array-constructor", "'<array-size>'"),
        (type_var | positive_integer).err("type", "type-size").name(:size),
        str(">"),
        many(ws),
        str("("),
        many(ws),
        exp.err("array-constructor", "initialize-expression").name(:exp),
        many(ws),
        str(")")
      ).map do |x|
        ArrayConst.new(x.to_h)
      end
    end

    parser :gf_cons do # -> ArrayConst
      seq(
        key("GF").name(:tag),
        str("<").err("gf-constructor", "'<array-size>'"),
        (type_var | positive_integer).err("type", "type-size").name(:size),
        str(">"),
        many(ws),
        str("("),
        many(ws),
        exp.err("gf-constructor", "initialize-int-expression").name(:exp),
        many(ws),
        str(")")
      ).map do |x|
        GFConst.new(x.to_h)
      end
    end

    parser :skip do
      str("skip").map do |x|
        SkipExp.new(:tag => x[0].tag)
      end
    end

    parser :var_ref do
      var_name_allow_last.map do |s|
        VarRef.new(:tag => s[:tag], :name => s)
      end
    end

    # Literal Expression
    # --------------------

    parser :literal_exp do
      string_literal ^ char_literal ^ parenth_or_tuple_literal ^ array_literal ^ float_literal ^ int_literal ^ wrap_literal
    end

    parser :string_literal do
      seq(doublequote, many((backslash > (doublequote | backslash)) | non_doublequote) < doublequote).map do |cs|
        LiteralString.new(:tag => cs[0].tag, :entity => cs[1].map{|c| c.item}.join)
      end
    end

    parser :char_literal do
      seq(singlequote, ((backslash > item) | item) < singlequote).map do |c|
        LiteralChar.new(:tag => c[0].tag, :entity => c[1].item.ord.to_s)
      end
    end

    parser :parenth_or_tuple_literal do
      seq(
        key("(").name(:tag),
        many(ws),
        many1_fail(exp, comma_separator).name(:exps),
        many(ws) < str(")")
      ).map do |x|
        if x[:exps].size == 1
          x[:exps][0]
        else
          LiteralTuple.new(:tag => x[:tag], :entity => x[:exps])
        end
      end
    end

    parser :array_literal do
      seq(
        key("{").name(:tag),
        many(ws),
        many1_fail(exp, comma_separator).name(:exps),
        many(ws) < str("}")
      ).map do |x|
        LiteralArray.new(:tag => x[:tag], :entity => x[:exps])
      end
    end

    parser :int_literal do
      neg = seq(char("-"), positive_integer).map{|x| LiteralInt.new(:tag => x[0].tag, :entity => Symbol.new(:tag => x[0].tag, :desc => "-" + x[1][:desc]))}
      int_literal_unsigned | neg
    end

    parser :int_literal_unsigned do
      zero = char("0").map{|x| LiteralInt.new(:tag => x.tag, :entity => Symbol.new(:tag => x.tag, :desc => "0"))}
      pos = positive_integer.map{|i| LiteralInt.new(:tag => i[:tag], :entity => i) }
      zero | pos
    end

    parser :float_literal do
      pos = seq(many1(digit).name(:a), char("."), many1(digit).name(:b))
        .map{|x| LiteralFloat.new(:tag => x[:a][0].tag, :entity => Symbol.new(:desc => "#{x[:a]}.#{x[:b]}", :tag => x[:a][0].tag))}
      neg = seq(char("-"), many1(digit).name(:a), char("."), many1(digit).name(:b))
        .map{|x| LiteralFloat.new(:tag => x[:a][0].tag, :entity => Symbol.new(:desc => "-#{x[:a]}.#{x[:b]}", :tag => x[:a][0].tag))}
      pos | neg
    end

    parser :wrap_literal do
      wint = seq(str("Int("), int_literal < str(")")).map{|i| LiteralInt.new(i[1], :tag => i[0][0].tag)}
      wuint = seq(str("UInt("), int_literal_unsigned < str(")")).map{|i| LiteralUInt.new(i[1], :tag => i[0][0].tag)}
      wchar = seq(str("Char("), int_literal < str(")")).map{|i| LiteralChar.new(i[1], :tag => i[0][0].tag)}
      wuchar = seq(str("UChar("), int_literal_unsigned < str(")")).map{|i| LiteralUChar.new(i[1], :tag => i[0][0].tag)}
      wfloat = seq(str("Float("), float_literal < str(")")).map{|i| LiteralFloat.new(i[1], :tag => i[0][0].tag)}
      wdouble = seq(str("Double("), float_literal < str(")")).map{|i| LiteralDouble.new(i[1], :tag => i[0][0].tag)}
      wint | wuint | wchar | wuchar | wfloat | wdouble
    end
  end
end
