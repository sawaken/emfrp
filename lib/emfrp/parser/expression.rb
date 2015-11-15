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
        symbol("if").name(:keyword),
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
        str("match:"),
        many(ws),
        case_group.err("match-exp", "valid case statement").name(:cases)
      ).map do |x|
        proc{|e| MatchExp.new(x.to_h, :exp => e)}
      end
    end

    parser :match_with_single_case_op do
      seq(
        str("match"),
        many1(ws),
        pattern.err("match-exp", "invalid single-case").name(:pattern),
        many1(ws),
        str("to"),
        many1(ws),
        exp.err("match-exp", "invalid exp").name(:exp)
      ).map do |x|
        c = Case.new(:pattern => x[:pattern], :exp => x[:exp])
        proc{|e| MatchExp.new(:cases => [c], :exp => e)}
      end
    end

    parser :case_group do
      c = seq(
        pattern.name(:pattern),
        many1(ws).err("case-exp", "space"),
        str("->").err("case-exp", "'to'"),
        many1(ws),
        exp.err("match-exp", "invalid exp").name(:exp)
      ).map{|x| pp x; Case.new(x.to_h)}
      many1_fail(c, many1(ws)) < many1(ws) < str(":endcase")
    end

    parser :pattern do
      dont_care_pattern ^ name_pattern ^ recursive_pattern ^ no_arg_pattern ^ tuple_pattern ^ integral_pattern
    end

    parser :dont_care_pattern do
      symbol("_").map do |c|
        AnyPattern.new(:ref => nil, :keyword => c)
      end
    end

    parser :name_pattern do
      ident_begin_lower.map do |n|
        AnyPattern.new(:ref => n)
      end
    end

    parser :recursive_pattern do
      seq(
        tvalue_symbol.name(:name),
        many(ws),
        str("("),
        many(ws),
        many1_fail(pattern, comma_separator).err("pattern", "invalide pattern").name(:args),
        many(ws),
        symbol(")").name(:keyword),
        opt_fail(
          many(ws) > str("as") > many1(ws) > var_name.err("pattern", "invalid name")
        ).to_nil.name(:ref)
      ).map{|x| ValuePattern.new(x.to_h)}
    end

    parser :no_arg_pattern do
      seq(
        tvalue_symbol.name(:name),
        opt_fail(
          many1(ws) > str("as") > var_name.err("pattern", "invalid name")
        ).to_nil.name(:ref)
      ).map{|x| ValuePattern.new(x.to_h, :args => [])}
    end

    parser :tuple_pattern do
      seq(
        symbol("(").name(:keyword1),
        many(ws),
        pattern.err("tuple-pattern", "invalid child pattern").name(:arg_head),
        many(ws),
        str(",").err("tuple-pattern", "invalid child pattern"),
        many(ws),
        many1_fail(pattern, comma_separator).err("tuple-pattern", "invalid child pattern").name(:arg_tail),
        many(ws),
        symbol(")").name(:keyword2),
        opt_fail(
          many(ws) > str("as") > many1(ws) > var_name.err("tuple-pattern", "invalid name")
        ).to_nil.name(:ref)
      ).map do |x|
        args = [x[:arg_head]] + x[:arg_tail]
        TuplePattern.new(:args => args, :ref => x[:ref])
      end
    end

    parser :integral_pattern do
      integral_literal.map{|n| IntegralPattern.new(:val => n)}
    end

    # Operator Expression
    # --------------------

    parser :operator_exp do
      opexp = operator_general.map do |op|
        proc do |l, r|
          if l.is_a?(OperatorSeq)
            OperatorSeq.new(:seq => l[:seq] + [op, r])
          else
            OperatorSeq.new(:seq => [l, op, r])
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
        str("."),
        many(ws),
        ident_begin_lower.err("method_call", "invalid method name").name(:name),
        opt_fail(str("(") > many(ws) > many_fail(exp, comma_separator) < many(ws) < str(")"))
          .map{|x| x.flatten}.err("method_call", "invalid form of argument").name(:args)
      ).map do |x|
        proc{|receiver| FuncCall.new(x.to_h, :args => [receiver] + x[:args])}
      end
    end

    parser :atom do
      literal_exp ^ single_op ^ func_call ^ block_exp ^ gf_cons ^ value_cons ^ skip ^ var_ref
    end

    parser :single_op do
      seq(operator, many(ws), atom).map do |x|
        name = x[0].update(:desc => "@" + x[0][:desc])
        FuncCall.new(:name => x[0], :args => [x[2]])
      end
    end

    parser :func_call do
      seq(
        func_name.name(:name),
        str("(") > many(ws),
        many1_fail(exp, comma_separator).name(:args),
        many(ws) > str(")")
      ).map do |x|
        FuncCall.new(x.to_h)
      end
    end

    parser :block_exp do
      seq(
        symbol("{").name(:keyword1),
        many(ws),
        many_fail(many(ws) > assign).name(:assigns),
        many(ws),
        str("=>").err("block-exp", "'=>'"),
        many(ws),
        exp.err("block-exp", "valid return-exp").name(:exp),
        many(ws),
        symbol("}").name(:keyword2)
      ).map do |x|
        BlockExp.new(x.to_h)
      end
    end

    parser :assign do
      seq(
        pattern.name(:pattern),
        many(ws),
        str("="),
        many(ws),
        exp.err("assign", "invalid assign statement").name(:exp)
      ).map do |x|
        Assign.new(x.to_h)
      end
    end

    parser :value_cons do # -> ValueConst
      seq(
        tvalue_symbol.name(:name),
        opt_fail(
          seq(
            many(ws),
            str("("),
            many(ws),
            many_fail(exp, comma_separator).name(:args),
            many(ws),
            symbol(")").name(:keyword)
          ).map{|x| x[:args]}
        ).map(&:flatten).err("value-construction", "invalid form of argument").name(:args)
      ).map do |x|
        ValueConst.new(x.to_h)
      end
    end

    parser :gf_cons do # -> ArrayConst
      seq(
        symbol("GF").name(:keyword1),
        opt(positive_integer).to_nil.err("type", "type-size").name(:size),
        many(ws),
        str("("),
        many(ws),
        exp.err("gf-constructor", "initialize-int-expression").name(:exp),
        many(ws),
        symbol(")").name(:keyword2)
      ).map do |x|
        GFConst.new(x.to_h)
      end
    end

    parser :skip do
      symbol("skip").map do |x|
        SkipExp.new(:keyword => x)
      end
    end

    parser :var_ref do
      var_name_allow_last.map do |s|
        VarRef.new(:name => s)
      end
    end

    # Literal Expression
    # --------------------

    parser :literal_exp do
      string_literal ^ char_literal ^ parenth_or_tuple_literal ^ array_literal ^ floating_literal ^ integral_literal
    end

    parser :string_literal do
      seq(
        symbol('"').name(:keyword1),
        many((backslash > (doublequote | backslash)) | non_doublequote)
          .map{|items| items.map{|i| i.item}.join}
          .name(:entity),
        symbol('"').name(:keyword2)
      ).map do |x|
        LiteralString.new(x.to_h)
      end
    end

    parser :char_literal do
      seq(
        symbol("'").name(:keyword1),
        ((backslash > item) | item).map{|i| i.item}.name(:entity),
        symbol("'").name(:keyword2),
      ).map do |x|
        LiteralChar.new(x.to_h)
      end
    end

    parser :parenth_or_tuple_literal do
      seq(
        symbol("(").name(:keyword1),
        many(ws),
        many1_fail(exp, comma_separator).name(:entity),
        many(ws),
        symbol(")").name(:keyword2)
      ).map do |x|
        if x[:entity].size == 1
          x[:entity].first
        else
          LiteralTuple.new(x.to_h)
        end
      end
    end

    parser :array_literal do
      seq(
        symbol("{").name(:keyword1),
        many(ws),
        many1_fail(exp, comma_separator).name(:entity),
        many(ws),
        symbol("}").name(:keyword2)
      ).map do |x|
        LiteralArray.new(x.to_h)
      end
    end

    parser :integral_literal do
      (positive_integer | zero_integer).map do |x|
        LiteralIntegral.new(:entity => x)
      end
    end

    parser :floating_literal do
      seq(
        integral_literal.name(:prefix),
        char("."),
        many1(digit).name(:suffix)
      ).map do |x|
        sym = SSymbol.new(:desc => x[:prefix][:entity][:desc] + "." + x[:suffix].map(&:item).join)
        LiteralFloating.new(:entity => sym)
      end
    end
  end
end
