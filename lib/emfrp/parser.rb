require 'parser_combinator/string'

module Emfrp
  class Parser < ParserCombinator::String
    def self.parse(src_str, filename)
      case res = whole_src.parse_from_string(convert_case_group(src_str), filename)
      when Fail
        ln = res.status.rest[0].tag[:line_number]
        col = res.status.rest[0].tag[:column_number]
        line = src_str.each_line.to_a[ln - 1]
        puts "#{filename}:#{ln}: Syntax error, in `#{res.status.message[:place]}`: required #{res.status.message[:required]}"
        puts "#{line}"
        puts "#{" " * (col - 1)}^ "
      else
        res
      end
    end

    def self.convert_case_group(src_str)
      raise "TAB Occur!!!" if src_str.chars.include?("\t")
      lines = src_str.each_line.to_a.map(&:chomp)
      len = lines.length
      len.times do |ln|
        if lines[ln].strip.chars.last == ":"
          width = lines[ln].chars.take_while{|c| c == "\s"}.size
          ((ln+1)..(len-1)).each do |ln2|
            width2 = lines[ln2].chars.take_while{|c| c == "\s"}.size
            if lines[ln2].strip == ""
              next
            elsif width2 <= width
              lines[ln2 - 1] << " :endcase"
              break
            elsif ln2 == len - 1
              lines[ln2] << " :endcase"
              break
            end
          end
        end
      end
      lines.map{|l| l + "\n"}.join
    end

    def err(place, required)
      self.onfail(:place => place, :required => required)
    end

    class Syntax < Hash
      def initialize(hash)
        self[:class] = self.class
        self.merge!(hash)
      end
    end

    Types = [
      :InputDef, :OutputDef, :DataDef, :FuncDef, :MethodDef, :NodeDef, :TypeDef, :InfixDef,
      :ParamDef, :Type, :TValue, :TValueParam, :NodeConst, :InitDef, :LazyDef,
      :NodeParam, :NodeLast, :NodeConstLift, :NodeConstClockEvery, :NodeConstInputQueue,
      :MapExp, :MatchExp, :Case, :Pattern, :OperatorExp,
      :MethodCall, :FuncCall, :BlockExp, :Assign, :ValueConst,
      :LiteralTuple, :LiteralArray, :LiteralString,
      :LiteralInt, :LiteralUInt, :LiteralChar, :LiteralUChar, :LiteralFloat, :LiteralDouble
    ]
    Types.each do |t|
      const_set(t, Class.new(Syntax))
    end

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

    # Expression
    # --------------------

    parser :exp do
      seq_operation
    end

    # Builtin Operator Expression
    # --------------------

    parser :seq_operation do
      x = map_with_group_case_op ^ map_with_single_case_op ^ match_with_group_case_op ^ match_with_single_case_op
      binopl_fail(operator_exp, many1(ws) > x < many1(ws))
    end

    parser :map_with_group_case_op do
      (str("map:") > case_group.err("map-exp", "invalid case statement")).map do |cs|
        proc{|l, r| MapExp.new(:left => l, :right => r, :cases => cs)}
      end
    end

    parser :map_with_single_case_op do
      seq(
        str("map"),
        many1(ws),
        pattern.err("map-exp", "invalid single-case").name(:pattern),
        many1(ws),
        str("to"),
        many1(ws),
        exp.err("map-exp", "invalid exp").name(:exp)
      ).map do |x|
        proc{|l, r| MapExp.new(:left => l, :right => r, :cases => [Case.new(x.to_h)])}
      end
    end

    parser :match_with_group_case_op do
      (str("match:") > case_group.err("match-exp", "invalid case statement")).map do |cs|
        proc{|l, r| MatchExp.new(:left => l, :right => r, :cases => cs)}
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
        proc{|l, r| MatchExp.new(:left => l, :right => r, :cases => [Case.new(x.to_h)])}
      end
    end

    parser :case_group do
      c = seq(
        str("case"),
        many1(ws),
        pattern.err("match-exp", "invalid single-case").name(:pattern),
        many1(ws),
        str("to"),
        many1(ws),
        exp.err("match-exp", "invalid exp").name(:exp)
      ).map{|x| Case.new(x.to_h)}
      many1_fail(c, many1(ws)) < many(ws) < str(":endcase")
    end

    parser :pattern do
      dontcare = (char("_") | str("otherwise")).map{ Pattern.new(:var => nil)}
      namematch = ident_begin_lower.map{|n| Pattern.new(:var => n)}
      recmatch = seq(
        tvalue_symbol.name(:tvalue_symbol),
        opt_fail(many(ws) > str("(") > many(ws) > many1_fail(pattern, comma_separator) < many(ws) < str(")") < many(ws))
          .map{|x| x.flatten}.err("pattern", "invalide pattern").name(:children),
        opt_fail(many1(ws) > str("as") > ident_begin_lower.err("pattern", "invalid name")).map{|x| x[0]}.name(:var)
      ).map{|x| Pattern.new(x.to_s)}
      dontcare | namematch | recmatch
    end

    # Operator Expression
    # --------------------

    parser :operator_exp do
      operator_app = operator ^ (char("`") > func_name < char("`"))
      opexp = operator_app.map{|op| proc{|l, r| OperatorExp.new(:left => l, :right => r, :op => op)}}
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
        ident_begin_lower.err("method_call", "invalid method name").name(:method_name),
        opt_fail(many(ws) > str("(") > many(ws) > many_fail(exp, comma_separator) < many(ws) < str(")") < many(ws))
          .map{|x| x.flatten}.err("method_call", "invalid form of argument").name(:args)
      ).map do |x|
        proc{|receiver| MethodCall.new(x.to_h.merge(:receiver => receiver))}
      end
    end

    parser :atom do
      literal_exp ^ func_call ^ block_exp ^ parenth_exp ^ value_cons ^ var_name_allow_last
    end

    parser :func_call do
      seq(
        func_name.name(:func_name),
        many(ws) > str("(") > many(ws),
        many1_fail(exp, comma_separator).name(:args),
        many(ws) > str(")")
      ).map do |x|
        FuncCall.new(x.to_h)
      end
    end

    parser :block_exp do
      seq(
        str("{"),
        many(ws),
        many(many(ws) > assign).name(:assigns),
        many(ws),
        str("=>").err("block-exp", "'=>'"),
        many(ws),
        exp.name(:exp),
        many(ws),
        str("}")
      ).map do |x|
        BlockExp.new(x.to_h)
      end
    end

    parser :assign do
      seq(
        var_name.name(:var_name),
        many(ws) > (str("=") > many(ws) > exp.name(:exp).err("assign", "invalid assign statement"))
      ).map do |x|
        Assign.new(x.to_h)
      end
    end

    parser :parenth_exp do
      str("(") > many(ws) > exp < many(ws) < str(")")
    end

    parser :value_cons do
      seq(
        tvalue_symbol.name(:tvalue_name),
        opt_fail(many(ws) > str("(") > many(ws) > many_fail(exp, comma_separator) < many(ws) < str(")") < many(ws))
          .map{|x| x.flatten}.err("value-construction", "invalid form of argument").name(:args)
      ).map do |x|
        ValueConst.new(x.to_h)
      end
    end

    # Literal Expression
    # --------------------

    parser :literal_exp do
      string_literal | char_literal | tuple_literal | array_literal | float_literal | int_literal | wrap_literal
    end

    parser :string_literal do
      (doublequote > many((backslash > (doublequote | backslash)) | non_doublequote) < doublequote).map do |cs|
        LiteralString.new(:entity => cs.map{|c| c.item}.join)
      end
    end

    parser :char_literal do
      (singlequote > ((backslash > item) | item) < singlequote).map do |c|
        LiteralChar.new(:entity => c.item.ord.to_s)
      end
    end

    parser :tuple_literal do
      seq(
        str("(") < many(ws),
        exp.name(:head) < many(ws),
        many1_fail(exp, comma_separator).name(:rest),
        many(ws) < str(")")
      ).map do |x|
        LiteralTuple.new(:entity => [x[:head]] + x[:rest])
      end
    end

    parser :array_literal do
      seq(
        str("{") < many(ws),
        many1_fail(exp, comma_separator).name(:exps),
        many(ws) < str("}")
      ).map do |x|
        LiteralArray.new(:entity => x[:exps])
      end
    end

    parser :int_literal do
      neg = (str("-") > positive_integer).map{|i| LiteralInt.new(:entity => "-" + i) }
      int_literal_unsigned | neg
    end

    parser :int_literal_unsigned do
      zero = str("0").map{ LiteralInt.new(:entity => "0") }
      pos = positive_integer.map{|i| LiteralInt.new(:entity => i) }
      zero | pos
    end

    parser :float_literal do
      pos = seq(many1(digit).name(:a), char("."), many1(digit).name(:b))
        .map{|x| LiteralFloat.new(:entity => "#{x[:a]}.#{x[:b]}" )}
      neg = seq(char("-"), many1(digit).name(:a), char("."), many1(digit).name(:b))
        .map{|x| LiteralFloat.new(:entity => "-#{x[:a]}.#{x[:b]}" )}
      pos | neg
    end

    parser :wrap_literal do
      wint = str("Int(") > int_literal < str(")")
      wuint = (str("UInt(") > int_literal_unsigned < str(")")).map{|i| LiteralUInt.new(i)}
      wchar = (str("Char(") > int_literal < str(")")).map{|i| LiteralChar.new(i)}
      wuchar = (str("UChar(") > int_literal_unsigned < str(")")).map{|i| LiteralUChar.new(i)}
      wfloat = (str("Float(") > float_literal < str(")")).map{|i| LiteralFloat.new(i)}
      wdouble = (str("Double(") > float_literal < str(")")).map{|i| LiteralDouble.new(i)}
      wint | wuint | wchar | wuchar | wfloat | wdouble
    end

    # Utils & Commons
    # --------------------

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

    parser :ident_begin_lower do # -> Item[String]
      seq(lower_alpha, many(lower_alpha | upper_alpha | digit | char("_"))).map do |xs|
        items = [xs[0]] + xs[1]
        Item.new(items.map{|i| i.item}.join, xs[0].tag)
      end
    end

    parser :ident_begin_upper do # -> Item[String]
      seq(upper_alpha, many(lower_alpha | upper_alpha | digit | char("_"))).map do |xs|
        items = [xs[0]] + xs[1]
        Item.new(items.map{|i| i.item}.join, xs[0].tag)
      end
    end

    parser :positive_integer do # -> Integer
      seq(pdigit, many(digit)).map do |x|
        ([x[0]] + x[1]).map{|i| i.item}.join.to_s
      end
    end

    parser :cfunc_name do
      ident_begin_lower | ident_begin_upper
    end

    parser :func_name do
      ident_begin_lower
    end

    parser :data_name do
      ident_begin_lower
    end

    parser :method_name do
      operator | ident_begin_lower
    end

    parser :var_name do
      ident_begin_lower
    end

    parser :node_instance_name do
      ident_begin_lower
    end

    parser :var_name_allow_last do
      (ident_begin_lower < str("@last")).map{|i| Item.new(i.item + "@last", i.tag)} | ident_begin_lower
    end

    parser :operator do
      usable = "!#$%&*+./<=>?@\\^|-~".chars.map{|c| char(c)}.inject(&:|)
      ng = ["..", ":", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>", "."]
      many1(usable) >> proc{|cs|
        token = cs.map{|i| i.item}.join
        if ng.include?(ng)
          fail.err("operator", "operator #{token} is not allowed")
        else
          ok(Item.new(token, cs[0].tag))
        end
      }
    end

    # Top Level Definition Statements
    # --------------------

    parser :whole_src do
      many(ws) > many_fail(top_def, many(ws)) < many(ws) < end_of_input.err("toplevel", "valid statement")
    end

    parser :top_def do
      input_def ^ output_def ^ data_def ^ func_def ^ method_def ^ node_def ^ node_def_by_constructor
    end

    parser :input_def do # -> InputDef
      seq(
        str("input"),
        opt(many1(ws) > init_def).map{|x| x == [] ? nil : x[0]}.name(:init),
        many1(ws),
        node_instance_name.err("input-def", "name of node").name(:name),
        many(ws),
        str(":").err("input-def", "':' after node-name"),
        many(ws),
        type.err("input-def", "type").name(:type),
        many(ws),
        str("<-").err("input-def", "'<-'"),
        many(ws),
        (cfunc_name < end_of_def).err("input-def", "name of C's function").name(:cfun)
      ).map do |x|
        InputDef.new(x.to_h)
      end
    end

    parser :output_def do # -> OutputDef
      seq(
        str("output"),
        many1(ws),
        opt(str("*")).map{|x| x != []}.name(:asta_flag),
        node_name.err("output-def", "name of node or node constructor").name(:node),
        many(ws),
        str("->").err("output-def", "'->'"),
        many(ws),
        (cfunc_name < end_of_def).err("output-def", "name of C's function").name(:cfun)
      ).map do |x|
        OutputDef.new(x.to_h)
      end
    end

    parser :data_def do # -> DataDef
      seq(
        str("data"),
        many1(ws),
        data_name.err("data-def", "name of data").name(:name),
        many(ws),
        str(":").err("data-def", "':'"),
        many(ws),
        type.err("data-def", "type").name(:type),
        many(ws),
        (body_def < end_of_def).err("data-def", "body").name(:body)
      ).map do |x|
        DataDef.new(x.to_h)
      end
    end

    parser :func_def do # -> FuncDef
      seq(
        str("func"),
        many1(ws),
        func_name.err("func-def", "name of func").name(:name),
        many(ws),
        str("("),
        many1_fail(func_param_def, comma_separator).err("func-def", "list of param for function"),
        str(")"),
        many(ws),
        str(":").err("func-def", "':'"),
        many(ws),
        type.err("func-def", "type of return value").name(:type),
        many(ws),
        (body_def < end_of_def).err("func-def", "body").name(:body)
      ).map do |x|
        FuncDef.new(x.to_h)
      end
    end

    parser :method_def do # -> MethodDef
      seq(
        str("method") > many1(ws),
        type_with_var.err("method-def", "type of receiver").name(:receiver_type),
        str("#").err("method-def", "'#'"),
        method_name.err("method-def", "method name").name(:method_name),
        many(ws),
        str("("),
        many_fail(func_param_def, comma_separator).err("method-def", "list of param for method"),
        str(")"),
        many(ws),
        str(":").err("method-def", "':'"),
        many(ws),
        type.err("method-def", "type of return value").name(:type),
        many(ws),
        (body_def < end_of_def).err("method-def", "body").name(:body)
      ).map do |x|
        MethodDef.new(x.to_h)
      end
    end

    parser :node_def do # -> NodeDef
      seq(
        str("node"),
        many_fail(many1(ws) > node_decolator).err("node-def", "node-decolator").name(:decos),
        many1(ws),
        node_instance_name.err("node-def", "node name").name(:node_name),
        many(ws),
        str("("),
        many1_fail(node_param, comma_separator).err("node-def", "list of param for node"),
        str(")"),
        many(ws),
        str(":").err("node-def", "':'"),
        many(ws),
        type.err("node-def", "type of return value").name(:type),
        many(ws),
        (body_def < end_of_def).err("node-def", "body").name(:body)
      ).map do |x|
        NodeDef.new(x.to_h)
      end
    end

    parser :node_def_by_constructor do # -> NodeDef
      seq(
        str("node"),
        many_fail(many1(ws) > node_decolator).err("node-def", "node-decolator").name(:decos),
        many1(ws),
        node_instance_name.err("node-def", "node name").name(:node_name),
        many(ws),
        str(":").err("node-def", "':'"),
        many(ws),
        type.err("node-def", "type of return value").name(:type),
        many(ws),
        str("=").err("node-def", "'='"),
        many(ws),
        (node_constructor < end_of_def).err("node-def", "node-constructor").name(:body)
      ).map do |x|
        NodeDef.new(x.to_h)
      end
    end

    parser :type_def do # -> TypeDef
      seq(
        str("type"),
        many1(ws),
        type_with_param.err("type-def", "type with param").name(:name),
        many(ws),
        str("=").err("type-def", "'='"),
        many(ws),
        (many1_fail(tvalue_def, or_separator) < end_of_def).err("type-def", "value constructors").name(:tvalues)
      ).map do |x|
        TypeDef.new(x.to_h)
      end
    end

    parser :infix_def do # -> InfixDef
      seq(str("infixl") | str("infixr") | str("infix"), many1(ws), digit, many1(ws) > operator < end_of_def). map do |x|
        InfixDef.new(:type => x[0].map{|i| i.item}.join.to_sym, :priority => x[1], :op => x[2])
      end
    end

    # Func associated
    # --------------------

    parser :func_param_def do # -> ParamDef
      seq(
        var_name.name(:var_name),
        many(ws),
        str(":").err("param-def", "':'"),
        many(ws),
        type_with_var.err("param-def", "type with type-var").name(:type)
      ).map do |x|
        ParamDef.new(x.to_h)
      end
    end

    # Body associated
    # --------------------

    parser :cexp do
      (many(ws) > many1(notchar("}"))).map{|cs| Item.new(cs.map{|x| x.item}.join.strip, cs[0].tag)}
    end

    parser :body_def do
      exp_def = str("=") > many(ws) > exp.err("body-def", "valid expression")
      cexp_def = str("{") > cexp < str("}").err("body-def", "'}' after c-expression")
      c_def = str("<-") > many(ws) > (cfunc_name | cexp_def).err("body-def", "c-function name or c-expression")
      exp_def ^ c_def
    end

    # Node associated
    # --------------------

    def self.node_constructor_gen(ast_type, name, args)
      seq(
        str(name).name(:name),
        many(ws),
        str("[").err("node-constructor", "[args]"),
        many(ws),
        args.err("arguments for #{name}", "valid arguments").name(:args),
        many(ws),
        str("]").err("node-constructor", "']' at end of args"),
      ).map do |xs|
        ast_type.new(xs.to_h)
      end
    end

    parser :node_param do
      seq(
        node_name.name(:name),
        opt_fail(str("as") > var_name.err("node-parameter", "name as exposed")).map{|x| x[0]}.name(:as)
      ).map do |xs|
        NodeParam.new(xs.to_h)
      end
    end

    parser :node_decolator do
      str("lazy").map{ LazyDef.new } | init_def
    end

    parser :init_def do # -> InitDef
      bra = str("[") > many(ws) > exp < many(ws) < str("]")
      (str("init") > many(ws) > bra.err("init-decolator", "'[' init-expression ']'")).map{|x| InitDef.new(:exp => x)}
    end

    parser :node_name do
      node_name_last | node_instance_name | node_constructor
    end

    parser :node_constructor do
      lift | clock_every | input_queue
    end

    parser :node_name_last do
      (node_instance_name < str("@last")).map{|x| NodeLast.new(:name => x)}
    end

    parser :lift do
      args = seq(
        func_name.name(:func_name),
        comma_separator,
        many1_fail(node_name, comma_separator).err("2nd, 3rd, ... arguments for Lift", "node-names").name(:nodes)
      ).err("argument for Lift", "[Function-name, Node-name1, Node-name2, ...] such as Lift[myfunc, n1, n2]")
        .map{|x| x.to_h}
      node_constructor_gen(NodeConstLift, "Lift", args)
    end

    parser :clock_every do
      args = seq(
        positive_integer.name(:clock),
      ).err("argument for InputQueue", "[Interval] such as ClockEvery[10]").map{|x| x.to_h}
      node_constructor_gen(NodeConstClockEvery, "ClockEvery", args)
    end

    parser :input_queue do
      args = seq(
        string_literal.name(:name),
        comma_separator,
        type.name(:type),
        comma_separator,
        positive_integer.name(:size),
      ).err("argument for InputQueue",
         "[String of queue-name, Type of queue entity, Size of queue] such as InputQueue[\"myqueue\", Int, 10]")
         .map{|x| x.to_h}
      node_constructor_gen(NodeConstInputQueue, "InputQueue", args)
    end

    # Type associated
    # --------------------

    def self.type_parser_gen(inner, type_size)
      seq(type_symbol, opt_fail(str("<") > type_size.err("type", "type-size") < str(">"))) >> proc{|x|
        type_args = many1_fail(inner, comma_separator).err("type", "list of type for '#{x[0]}'s type-argument")
        opt_fail(str("[") > type_args < str("]").err("type", "']'")).map do |args|
          Type.new(:name => x[0], :args => args.flatten, :size => x[1][0])
        end
      }
    end

    def self.type_tuple_parser_gen(inner)
      type_args = many1_fail(inner, comma_separator).err("type", "list of type for Tuple's type-argument")
      seq(str("("), type_args < str(")").err("type", "')'")).map do |xs|
        Type.new(:name => Item.new("Tuple", xs[0][0].tag), :args => xs[1])
      end
    end

    parser :type_symbol do
      ident_begin_upper
    end

    parser :tvalue_symbol do
      ident_begin_upper
    end

    parser :type_var do
      ident_begin_lower
    end

    parser :type do
      type_parser_gen(type, positive_integer) ^ type_tuple_parser_gen(type)
    end

    parser :type_with_var do
      type_var | type_parser_gen(type_with_var, type_var | positive_integer) ^ type_tuple_parser_gen(type_with_var)
    end

    parser :type_with_param do
      type_parser_gen(type_var, type_var) ^ type_tuple_parser_gen(type_var)
    end

    parser :tvalue_def do # -> TValue
      seq(
        tvalue_symbol.name(:name),
        many(ws),
        opt_fail(str("(") > many1_fail(tvalue_def_type, comma_separator) < str(")")
          .err("value-constructor-def", "')'")).map{|x| x.flatten}.name(:params),
        many(ws)
      ).map do |x|
        TValue.new(x.to_h)
      end
    end

    parser :tvalue_def_type do # -> TValueParam
      colon = (many(ws) < str(":") < many(ws)).err("value-constructor-parameter-def", "':' after name")
      seq(
        opt_fail(func_name < colon).map{|x| x == [] ? nil : x[0]}.name(:name),
        type_with_var.name(:type)
      ).map do |x|
        TValueParam.new(x.to_h)
      end
    end
  end
end
