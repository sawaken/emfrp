require 'parser_combinator/string_parser'

module Emfrp
  class Parser < ParserCombinator::StringParser

    # Top Level Definition Statements
    # --------------------

    parser :whole_src do
      many(ws) > many_fail(top_def, many(ws)) < many(ws) < end_of_input.err("toplevel", "valid statement")
    end

    parser :top_def do
      input_def ^ output_def ^ data_def ^ func_def ^ method_def ^ node_def ^ node_def_by_constructor ^
      type_def ^ infix_def
    end

    parser :input_def do # -> InputDef
      seq(
        key("input").name(:tag),
        opt(many1(ws) > decolator_def).map{|x| x == [] ? nil : x[0]}.name(:decolator),
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
        key("output").name(:tag),
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
        key("data").name(:tag),
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
        key("func").name(:tag),
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
        key("method").name(:tag),
        many1(ws),
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
        key("node").name(:tag),
        opt(many1(ws) > init_def).map{|x| x == [] ? nil : x[0]}.name(:init),
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
        key("node").name(:tag),
        opt(many1(ws) > init_def).map{|x| x == [] ? nil : x[0]}.name(:init),
        many1(ws),
        node_instance_name.err("node-def", "node name").name(:node_name),
        many(ws),
        str(":").err("node-def", "':'"),
        many(ws),
        type.err("node-def", "type of return value").name(:type),
        many(ws),
        str("=").err("node-def", "'='"),
        many(ws),
        (node_constructor < end_of_def).err("node-def", "node-constructor").name(:constructor)
      ).map do |x|
        NodeDef.new(x.to_h)
      end
    end

    parser :type_def do # -> TypeDef
      seq(
        key("type").name(:tag),
        opt(many1(ws) > str("static")).map{|x| x == [] ? false : true}.name(:static),
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
      seq(
        (str("infixl") | str("infixr") | str("infix")).map{|s| [s[0].tag, s.map(&:item).join.to_sym]}.name(:type),
        many1(ws),
        digit.err("infix-def", "digit of priority").name(:priority),
        many1(ws),
        operator.err("infix-def", "operator").name(:op),
        end_of_def
      ). map do |x|
        InfixDef.new(:tag => x[:type][0], :type => x[:type][1], :priority => x[:priority], :op => x[:op])
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
        ParamDef.new(x.to_h, :tag => x[0][:tag])
      end
    end

    # Body associated
    # --------------------

    parser :cexp do
      (many(ws) > many1(notchar("}"))).map{|cs| CExp.new(:desc => cs.map{|x| x.item}.join.strip, :tag =>cs[0].tag)}
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
        symbol(name).name(:name),
        many(ws),
        str("[").err("node-constructor", "[args]"),
        many(ws),
        args.err("arguments for #{name}", "valid arguments").name(:args),
        many(ws),
        str("]").err("node-constructor", "']' at end of args"),
      ).map do |xs|
        ast_type.new(xs.to_h, :tag => xs[:name][:tag])
      end
    end

    parser :node_param do
      seq(
        node_name.name(:name),
        opt_fail(str("as") > var_name.err("node-parameter", "name as exposed")).map{|x| x[0]}.name(:as)
      ).map do |xs|
        NodeParam.new(xs.to_h, :tag => xs[:name][:tag])
      end
    end

    parser :decolator_def do
      lazy_def | init_def
    end

    parser :lazy_def do # -> LazyDef
      symbol("lazy").map{|i| LazyDef.new(:tag => i[:tag]) }
    end

    parser :init_def do # -> InitDef
      bra = str("[") > many(ws) > exp < many(ws) < str("]")
      (str("init") > many(ws) > bra.err("init-decolator", "'[' init-expression ']'")).map{|x| InitDef.new(:exp => x, :tag => x[:tag])}
    end

    parser :node_name do
      node_name_last | node_instance_name | node_constructor
    end

    parser :node_constructor do
      lift | clock_every | input_queue
    end

    parser :node_name_last do
      (node_instance_name < str("@last")).map{|x| NodeLast.new(:name => x, :tag => x[:tag])}
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
          Type.new(:tag => x[0][:tag], :name => x[0], :args => args.flatten, :size => x[1][0])
        end
      }
    end

    def self.type_tuple_parser_gen(inner)
      type_args = many1_fail(inner, comma_separator).err("type", "list of type for Tuple's type-argument")
      seq(str("("), type_args < str(")").err("type", "')'")).map do |xs|
        TupleType.new(:tag => xs[0][0].tag, :args => xs[1])
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
        TValue.new(x.to_h, :tag => x[:name][:tag])
      end
    end

    parser :tvalue_def_type do # -> TValueParam
      colon = (many(ws) < str(":") < many(ws)).err("value-constructor-parameter-def", "':' after name")
      seq(
        opt_fail(func_name < colon).map{|x| x == [] ? nil : x[0]}.name(:name),
        type_with_var.name(:type)
      ).map do |x|
        TValueParam.new(x.to_h, :tag => x[:name] ? x[:name][:tag] : x[:type][:tag])
      end
    end
  end
end
