require 'parser_combinator/string_parser'

module Emfrp
  class Parser < ParserCombinator::StringParser

    # Top Level Definition Statements
    # --------------------

    parser :whole_src do
      many(ws) > many_fail(top_def, many(ws)) < many(ws) < end_of_input.err("toplevel", "valid statement")
    end

    parser :top_def do
      input_def ^ output_def ^ data_def ^ func_def ^ node_def ^
      type_def ^ ctype_def ^ infix_def
    end

    parser :input_def do # -> InputDef
      seq(
        key("input").name(:tag),
        opt(many1(ws) > decolator_def).map{|x| x == [] ? nil : x[0]}.name(:decolator),
        many1(ws),
        node_instance_name.err("input-def", "name of node").name(:name),
        many(ws),
        str(":").err("input-def", "': [Type]'  after node-name"),
        many(ws),
        type.err("input-def", "type").name(:type),
        many(ws),
        cfunc_def.err("input-def", "C's function-name after '<-'").name(:cfunc),
        end_of_def.err("input-def", "valid end of input-def")
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
        (cfunc_name < end_of_def).err("output-def", "name of C's function").name(:cfunc)
      ).map do |x|
        OutputDef.new(x.to_h)
      end
    end

    parser :initialize_def do # -> InitializeDef
      seq(
        key("initialize").name(:tag),
        many(ws),
        cfunc_def.name(:cfunc),
        end_of_def
      ).map do |x|
        InitializeDef.new(x.to_h)
      end
    end

    parser :data_def do # -> DataDef
      seq(
        key("data").name(:tag),
        many1(ws),
        data_name.err("data-def", "name of data").name(:name),
        opt_fail(
          many(ws) >
          str(":") >
          many(ws) >
          type.err("data-def", "type")
        ).to_nil.name(:type),
        many(ws),
        (exp_def ^ cfunc_def).err("data-def", "body").name(:body),
        end_of_def.err("data-def", "valid end of data-def")
      ).map do |x|
        DataDef.new(x.to_h)
      end
    end

    parser :func_def do # -> FuncDef
      seq(
        key("func").name(:tag),
        many1(ws),
        (func_name | operator).err("func-def", "name of func").name(:name),
        many(ws),
        str("("),
        many1_fail(func_param_def, comma_separator).err("func-def", "list of param for function").name(:params),
        str(")"),
        opt_fail(
          many(ws) >
          str(":") >
          many(ws) >
          type.err("func-def", "type of return value")
        ).to_nil.name(:type),
        many(ws),
        (body_def < end_of_def).err("func-def", "body").name(:body)
      ).map do |x|
        FuncDef.new(x.to_h)
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
        many1_fail(node_param, comma_separator).err("node-def", "list of param for node").name(:params),
        str(")"),
        many(ws),
        str(":").err("node-def", "': [Type]'"),
        many(ws),
        type.err("node-def", "type of return value").name(:type),
        many(ws),
        exp_def.err("node-def", "body").name(:exp),
        end_of_def.err("node-def", "valid end of node-def")
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

    parser :ctype_def do # -> CTypeDef
      seq(
        key("ctype").name(:tag),
        many1(ws),
        type_symbol.err("ctype-def", "type symbol to be define").name(:name),
        many(ws),
        str("<-").err("ctype-def", "'<-'"),
        many(ws),
        (cfunc_name < end_of_def).err("ctype-def", "type symbol from C").name(:ctype)
      ).map do |x|
        CTypeDef.new(x.to_h)
      end
    end

    parser :infix_def do # -> InfixDef
      seq(
        (symbol("infixl") | symbol("infixr") | symbol("infix")).name(:type),
        opt(many1(ws) > digit_symbol).to_nil.name(:priority),
        many1(ws),
        operator_general.err("infix-def", "operator").name(:op),
        end_of_def
      ). map do |x|
        InfixDef.new(:tag => x[:type][:tag], :type => x[:type], :priority => x[:priority], :op => x[:op])
      end
    end

    # Func associated
    # --------------------

    parser :func_param_def do # -> ParamDef
      seq(
        var_name.name(:var_name),
        opt_fail(
          many(ws) >
          str(":") >
          many(ws) >
          type_with_var.err("param-def", "type with type-var")
        ).to_nil.name(:type)
      ).map do |x|
        ParamDef.new(x.to_h, :tag => x[:var_name][:tag])
      end
    end

    # Body associated
    # --------------------

    parser :cexp do
      (many(ws) > many1(notchar("}"))).map do |cs|
        CExp.new(:desc => cs.map{|x| x.item}.join.strip, :tag =>cs[0].tag)
      end
    end

    parser :exp_def do
      str("=") > many(ws) > exp.err("body-def", "valid expression")
    end

    parser :cexp_def do
      str("<-") > many(ws) > str("{") > cexp < str("}").err("body-def", "'}' after c-expression")
    end

    parser :cfunc_def do
      str("<-") > many(ws) > cfunc_name
    end

    parser :body_def do
      exp_def ^ cexp_def ^ cfunc_def
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
        opt_fail(str("as") > var_name.err("node-parameter", "name as exposed")).to_nil.name(:as)
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
      input_queue
    end

    parser :node_name_last do
      (node_instance_name < str("@last")).map{|x| NodeLast.new(:name => x, :tag => x[:tag])}
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
        opt_fail(
          many(ws) >
          str("(") >
          many1_fail(tvalue_def_type, comma_separator) <
          str(")").err("value-constructor-def", "')'")
        ).map{|x| x.flatten}.name(:params),
      ).map do |x|
        TValue.new(x.to_h, :tag => x[:name][:tag])
      end
    end

    parser :tvalue_def_type do # -> TValueParam
      colon = (many(ws) < str(":") < many(ws))
      seq(
        opt_fail(func_name < colon).to_nil.name(:name),
        type_with_var.name(:type)
      ).map do |x|
        TValueParam.new(x.to_h, :tag => x[:name] ? x[:name][:tag] : x[:type][:tag])
      end
    end
  end
end
