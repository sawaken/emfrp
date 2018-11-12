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
        true_sym = SSymbol.new(:desc => "True")
        true_pat = ValuePattern.new(:name => true_sym, :args => [], :ref => nil, :type => nil)
        true_case = Case.new(:pattern => true_pat, :exp => x[:then])
        false_sym = SSymbol.new(:desc => "False")
        false_pat = ValuePattern.new(:name => false_sym, :args => [], :ref => nil, :type => nil)
        false_case = Case.new(:pattern => false_pat, :exp => x[:else])
        MatchExp.new(:exp => x[:cond], :cases => [true_case, false_case])
      end
    end

    parser :builtin_operation do
      x = match_with_indent_case_group_op ^ match_with_liner_case_group_op
      seq(
        operator_exp.name(:exp),
        many_fail(many1(ws) > x).name(:builtin_ops)
      ).map do |x|
        x[:builtin_ops].inject(x[:exp]) do |acc, ep|
          ep.call(acc)
        end
      end
    end

    parser :match_with_indent_case_group_op do
      seq(
        str("of:"),
        many(ws),
        case_group.err("match-exp", "valid case statement").name(:cases)
      ).map do |x|
        proc{|e| MatchExp.new(x.to_h, :exp => e)}
      end
    end

    parser :match_with_liner_case_group_op do
      seq(
        str("of"),
        many1(ws),
        many1_fail(
          seq(
            pattern.name(:pattern).name(:pattern),
            many1(ws),
            str("->").err("lienr-match-exp", "->"),
            many1(ws),
            exp.err("liner-match-exp", "invalid exp").name(:exp)
          ).map{|x| Case.new(x.to_h)},
          comma_separator
        ).name(:cases)
      ).map do |x|
        proc{|e| MatchExp.new(x.to_h, :exp => e)}
      end
    end

    parser :case_group do
      cs = seq(
        many1_fail(pattern, or_separator).name(:patterns),
        many1(ws).err("case-exp", "space"),
        str("->").err("case-exp", "'to'"),
        many1(ws),
        exp.err("match-exp", "invalid exp").name(:exp)
      ).map do |x|
        x[:patterns].map{|pat| Case.new(:pattern => pat, :exp => x[:exp].deep_copy)}
      end
      many1_fail(cs, many1(ws)).map(&:flatten) < many1(ws) < str(":endcase")
    end

    parser :pattern do
      pat = dont_care_pattern ^ name_pattern ^ recursive_pattern ^ no_arg_pattern ^ tuple_pattern ^ integral_pattern
      seq(
        pat.name(:pattern),
        opt_fail(
          many(ws) > str(":") > many(ws) >
          type.err("param-def", "type")
        ).to_nil.name(:type)
      ).map do |x|
        x[:pattern][:type] = x[:type]
        x[:pattern]
      end
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
        many1_fail(pattern, comma_separator).name(:args),
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
        pattern.name(:arg_head),
        many(ws),
        str(","),
        many(ws),
        many1_fail(pattern, comma_separator).name(:arg_tail),
        many(ws),
        symbol(")").name(:keyword2),
        opt_fail(
          many(ws) > str("as") > many1(ws) > var_name.err("tuple-pattern", "invalid name")
        ).to_nil.name(:ref)
      ).map do |x|
        args = [x[:arg_head]] + x[:arg_tail]
        ValuePattern.new(
          :name => SSymbol.new(:desc => "Tuple" + args.size.to_s),
          :args => args,
          :ref => x[:ref],
          :keyword1 => x[:keyword1],
          :keyword2 => x[:keyword2]
        )
      end
    end

    parser :integral_pattern do
      integral_literal.map{|n| IntegralPattern.new(:val => n, :ref => nil)}
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
        symbol(".").name(:keyword1),
        many(ws),
        ident_begin_lower.err("method_call", "invalid method name").name(:name),
        opt_fail(
          seq(
            many(ws_without_newline),
            symbol("(").name(:keyword2),
            many(ws),
            many_fail(exp, comma_separator).name(:args),
            many(ws),
            symbol(")").name(:keyword3)
          )
        ).to_nil.name(:args)
      ).map do |x|
        proc do |receiver|
          if x[:args]
            FuncCall.new(
              :name => x[:name],
              :keywords => [x[:keyword1], x[:args][:keyword2], x[:args][:keyword3]],
              :args => [receiver] + x[:args][:args]
            )
          else
            FuncCall.new(
              :name => x[:name],
              :keyword => x[:keyword1],
              :args => [receiver]
            )
          end
        end
      end
    end

    parser :atom do
      literal_exp ^ single_op ^ func_call ^ block_exp ^ value_cons ^ skip ^ var_ref
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
        many(ws_without_newline),
        symbol("(").name(:keyword1),
        many(ws),
        many1_fail(exp, comma_separator).name(:args),
        many(ws),
        symbol(")").name(:keyword2)
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
        exp.err("block-exp", "valid return-exp").name(:exp),
        many(ws),
        symbol("}").name(:keyword2)
      ).map do |x|
        x[:assigns].reverse.inject(x[:exp]) do |acc, a|
          c = Case.new(:pattern => a[:pattern], :exp => acc)
          MatchExp.new(:cases => [c], :exp => a[:exp])
        end
      end
    end

    parser :assign do # -> Hash
      seq(
        pattern.name(:pattern),
        many(ws),
        str("="),
        many(ws),
        exp.err("assign", "invalid assign statement").name(:exp)
      ).map do |x|
        x.to_h
      end
    end

    parser :value_cons do # -> ValueConst
      seq(
        tvalue_symbol.name(:name),
        opt_fail(
          seq(
            many(ws_without_newline),
            str("("),
            many(ws),
            many_fail(exp, comma_separator).name(:args),
            many(ws),
            symbol(")").name(:keyword)
          ).name(:args)
        ).to_nil.err("value-construction", "invalid form of argument").name(:args)
      ).map do |x|
        if x[:args]
          ValueConst.new(:name => x[:name], :args => x[:args][:args], :keyword => x[:args][:keyword])
        else
          ValueConst.new(:name => x[:name], :args => [])
        end
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
      char_literal ^ parenth_or_tuple_literal ^ floating_literal ^ integral_literal
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
          ParenthExp.new(
            :exp => x[:entity].first,
            :keyword1 => x[:keyword1],
            :keyword2 => x[:keyword2]
          )
        else
          ValueConst.new(
            :name => SSymbol.new(:desc => "Tuple" + x[:entity].size.to_s),
            :args => x[:entity],
            :parent_begin => x[:keyword1],
            :parent_end => x[:keyword2]
          )
        end
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
        LiteralFloating.new(
          :entity => sym,
          :start_pos => x[:prefix][:entity][:start_pos],
          :end_pos => x[:suffix][-1].tag
        )
      end
    end
  end
end
