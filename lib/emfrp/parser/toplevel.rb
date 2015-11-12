require 'parser_combinator/string_parser'

module Emfrp
  class Parser < ParserCombinator::StringParser

    # Top Level Definition Statements
    # --------------------

    parser :whole_src do
      seq(
        many(ws),
        many_fail(top_def, many(ws)).name(:defs),
        many(ws),
        end_of_input.err("toplevel", "valid statement")
      ).map do |x|
        t = Top.new
        x[:defs].each do |d|
          k = case d
          when InputDef then :inputs
          when OutputDef then :outputs
          when InitializeDef then :inits
          when DataDef then :datas
          when FuncDef then :funcs
          when NodeDef then :nodes
          when TypeDef then :types
          when CTypeDef then :ctypes
          when InfixDef then :infixes
          end
          t[k] << d
        end
        t
      end
    end

    parser :top_def do
      input_def ^ output_def ^ initialize_def ^ data_def ^ func_def ^ node_def ^
      type_def ^ ctype_def ^ infix_def
    end

    parser :input_def do # -> InputDef
      seq(
        symbol("input").name(:keyword),
        opt(many1(ws) > decolator_def).to_nil.name(:decolator),
        many1(ws),
        node_instance_name.err("input-def", "name of node").name(:name),
        many(ws),
        str(":").err("input-def", "': [Type]'  after node-name"),
        many(ws),
        type.err("input-def", "type").name(:type),
        many(ws),
        cfunc_body_def.err("input-def", "C's function-name after '<-'").name(:cfunc),
        end_of_def.err("input-def", "valid end of input-def")
      ).map do |x|
        InputDef.new(x.to_h)
      end
    end

    parser :output_def do # -> OutputDef
      seq(
        symbol("output").name(:keyword),
        many1(ws),
        opt(str("*")).map{|x| x != []}.name(:asta_flag),
        node_ref.err("output-def", "name of node or node constructor").name(:node),
        many(ws),
        str("->").err("output-def", "'->'"),
        many(ws),
        cfunc_name.err("output-def", "name of C's function").name(:cfunc),
        end_of_def.err("output-def", "valid end of output-def")
      ).map do |x|
        OutputDef.new(x.to_h)
      end
    end

    parser :initialize_def do # -> InitializeDef
      seq(
        symbol("initialize").name(:keyword),
        many(ws),
        cfunc_body_def.name(:cfunc),
        end_of_def
      ).map do |x|
        InitializeDef.new(x.to_h)
      end
    end

    parser :data_def do # -> DataDef
      seq(
        symbol("data").name(:keyword),
        many1(ws),
        data_name.err("data-def", "name of data").name(:name),
        opt_fail(
          many(ws) >
          str(":") >
          many(ws) >
          type.err("data-def", "type")
        ).to_nil.name(:type),
        many(ws),
        body_def.err("data-def", "body").name(:body),
        end_of_def.err("data-def", "valid end of data-def")
      ).map do |x|
        DataDef.new(x.to_h)
      end
    end

    parser :func_def do # -> FuncDef
      seq(
        symbol("func").name(:keyword),
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
          type_with_var.err("func-def", "type of return value")
        ).to_nil.name(:type),
        many(ws),
        body_def.err("func-def", "body").name(:body),
        end_of_def.err("func-def", "valid end of func-def")
      ).map do |x|
        FuncDef.new(x.to_h)
      end
    end

    parser :node_def do # -> NodeDef
      seq(
        symbol("node").name(:keyword),
        opt(many1(ws) > init_def).to_nil.name(:init),
        many1(ws),
        node_instance_name.err("node-def", "node name").name(:name),
        many(ws),
        str("("),
        many_fail(node_param, comma_separator).err("node-def", "list of param for node").name(:params),
        str(")"),
        opt_fail(
          many(ws) > str(":") > many(ws) > type.err("node-def", "[Type] after :")
        ).to_nil.name(:type),
        many(ws),
        exp_body_def.err("node-def", "body").name(:exp),
        end_of_def.err("node-def", "valid end of node-def")
      ).map do |x|
        NodeDef.new(x.to_h)
      end
    end

    parser :type_def do # -> TypeDef
      seq(
        symbol("type").name(:keyword),
        opt(many1(ws) > str("static")).map{|x| x == [] ? false : true}.name(:static),
        many1(ws),
        type_with_param.err("type-def", "type with param").name(:type),
        many(ws),
        opt_fail(
          seq(
            str("["),
            many1_fail(type_var, comma_separator).err("type-def", "valid params"),
            str("]").err("type-def", "']' after params")
          ).map{|x| x[1]}
        ).map{|x| x.flatten}.name(:params),
        many(ws),
        str("=").err("type-def", "'='"),
        many(ws),
        many1_fail(tvalue_def, or_separator).err("type-def", "value constructors").name(:tvalues),
        end_of_def.err("type-def", "valid end of type-def")
      ).map do |x|
        TypeDef.new(x.to_h)
      end
    end

    parser :ctype_def do # -> CTypeDef
      seq(
        symbol("ctype").name(:keyword),
        many1(ws),
        type_symbol.err("ctype-def", "type symbol to be define").name(:name),
        many(ws),
        str("<-").err("ctype-def", "'<-'"),
        many(ws),
        cfunc_name.err("ctype-def", "type symbol from C").name(:ctype),
        end_of_def.err("ctype-def", "valid end of ctype-def")
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
        InfixDef.new(x.to_h)
      end
    end

    # Initialize associated
    # --------------------

    parser :initialize_target_def do # -> InitializeTargetDef
      seq(
        many1(ws),
        data_name.name(:name),
        many(ws),
        str(":").err("initialize-def", "':' after name"),
        many(ws),
        type.err("initialize-def", "type").name(:type)
      ).map do |x|
        InitializeTargetDef.new(x.to_h)
      end
    end

    # Func associated
    # --------------------

    parser :func_param_def do # -> ParamDef
      seq(
        var_name.name(:name),
        opt_fail(
          many(ws) >
          str(":") >
          many(ws) >
          type_with_var.err("param-def", "type with type-var")
        ).to_nil.name(:type)
      ).map do |x|
        ParamDef.new(x.to_h)
      end
    end

    # Body associated
    # --------------------

    parser :cexp do
      seq(
        symbol("{").name(:keyword1),
        many(ws),
        many1(notchar("}")).name(:items),
        str("}").err("body-def", "'}' after c-expression").name(:keyword2)
      ).map do |x|
        CExp.new(
          :keyword1 => x[:keyword1],
          :keyword2 => x[:keyword2],
          :desc => x[:items].map(&:item).join.strip,
          :start_pos => x[:items][0].tag,
          :end_pos => x[:items][-1].tag
        )
      end
    end

    parser :exp_body_def do
      str("=") > many(ws) > exp.err("body-def", "valid expression")
    end

    parser :cexp_body_def do
      str("<-") > many(ws) > cexp
    end

    parser :cfunc_body_def do
      str("<-") > many(ws) > cfunc_name
    end

    parser :body_def do
      cexp_body_def ^ cfunc_body_def ^ exp_body_def
    end

    # Node associated
    # --------------------

    parser :node_param do
      node_ref | node_constructor
    end

    parser :node_ref do
      node_name_last | node_name_current
    end

    parser :decolator_def do
      lazy_def | init_def
    end

    parser :lazy_def do # -> LazyDef
      symbol("lazy").map do |x|
        LazyDef.new(:keyword => x)
      end
    end

    parser :init_def do # -> InitDef
      seq(
        symbol("init").name(:keyword1),
        many(ws),
        str("["),
        many(ws),
        exp.name(:exp),
        many(ws),
        symbol("]").name(:keyword)
      ).map do |x|
        InitDef.new(x.to_h)
      end
    end

    parser :node_constructor do
      input_queue
    end

    parser :node_name_last do
      seq(
        node_instance_name.name(:name),
        symbol("@last").name(:keyword),
        opt_fail(str("as") > var_name.err("node-parameter", "name as exposed")).to_nil.name(:as)
      ).map do |x|
        as = x[:as] || SSymbol.new(
          :desc => x[:name][:desc] + "@last",
          :start_pos => x[:name][:start_pos],
          :end_pos => x[:keyword][:end_pos]
        )
        NodeRef.new(:last => true, :as => as, :name => x[:name])
      end
    end

    parser :node_name_current do
      seq(
        node_instance_name.name(:name),
        opt_fail(str("as") > var_name.err("node-parameter", "name as exposed")).to_nil.name(:as)
      ).map do |x|
        NodeRef.new(:last => false, :as => x[:as] || x[:name], :name => x[:name])
      end
    end

    parser :input_queue do
      seq(
        symbol("InputQueue").name(:keyword1),
        many(ws),
        str("[").err("node-constructor", "[args]"),
        many(ws),
        string_literal.name(:name),
        comma_separator,
        type.name(:type),
        comma_separator,
        positive_integer.name(:size),
        many(ws),
        symbol("]").err("node-constructor", "']' at end of args").name(:keyword2),
      ).map do |x|
        NodeConstInputQueue.new(x.to_h)
      end
    end

    # Type associated
    # --------------------

    def self.type_parser_gen(inner, type_size)
      seq(
        type_symbol,
        opt_fail(str("<") > type_size.err("type", "type-size") < str(">")).to_nil.name(:size)
      ) >> proc{|x|
        type_args = many1_fail(inner, comma_separator).err("type", "list of type for '#{x[0]}'s type-argument")
        opt_fail(str("[") > type_args < str("]").err("type", "']'")).map do |args|
          Type.new(:name => x[0], :args => args.flatten, :size => x[:size])
        end
      }
    end

    def self.type_tuple_parser_gen(inner)
      type_args = many1_fail(inner, comma_separator).err("type", "list of type for Tuple's type-argument")
      seq(
        symbol("(").name(:keyword1),
        type_args.name(:args),
        symbol(")").err("type", "')'").name(:keyword2)
      ).map do |x|
        Type.new(x.to_h, :size => nil, :name => SSymbol.new(:desc => "Tuple"))
      end
    end

    parser :type_symbol do
      ident_begin_upper
    end

    parser :tvalue_symbol do
      ident_begin_upper
    end

    parser :type_var do # => TypeVar
      ident_begin_lower.map do |s|
        TypeVar.new(:name => s)
      end
    end

    parser :type do
      type_parser_gen(type, positive_integer) ^ type_tuple_parser_gen(type)
    end

    parser :type_with_var do
      type_var ^ type_parser_gen(type_with_var, type_var | positive_integer) ^ type_tuple_parser_gen(type_with_var)
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
        TValue.new(x.to_h)
      end
    end

    parser :tvalue_def_type do # -> TValueParam
      colon = (many(ws) < str(":") < many(ws))
      seq(
        opt_fail(func_name < colon).to_nil.name(:name),
        type_with_var.name(:type)
      ).map do |x|
        TValueParam.new(x.to_h)
      end
    end
  end
end
