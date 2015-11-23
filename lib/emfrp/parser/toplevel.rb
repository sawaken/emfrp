require 'parser_combinator/string_parser'

module Emfrp
  class Parser < ParserCombinator::StringParser

    # Top Level Definition Statements
    # --------------------

    parser :module_top_def do
      data_def ^ func_def ^ node_def ^ type_def ^ infix_def ^ primtype_def ^ primfunc_def
    end

    parser :material_top_def do
      data_def ^ func_def ^ type_def ^ infix_def ^ primtype_def ^ primfunc_def
    end

    parser :module_file do
      seq(
        many(ws),
        symbol("module").err("module-file", "keyword 'module'").name(:keyword1),
        many1(ws),
        ident_begin_upper.name(:name),
        many1(ws),
        symbol("in"),
        many1(ws),
        many1_fail(input_def, comma_separator).name(:inputs),
        many1(ws),
        symbol("out"),
        many1(ws),
        many1_fail(output_def, comma_separator).name(:outputs),
        opt_fail(
          many1(ws) >
          symbol("use") >
          many1(ws) >
          many1_fail(load_path, comma_separator) <
          many1(ws)
        ).map{|x| x == [] ? [] : x[0]}.name(:uses),
        many(ws),
        many_fail(module_top_def, many(ws)).name(:defs),
        many(ws),
        end_of_input.err("module-file", "valid end of file")
      ).map do |x|
        t = Top.new(:inputs => x[:inputs], :outputs => x[:outputs], :uses => x[:uses])
        x[:defs].each do |d|
          k = case d
          when DataDef then :datas
          when FuncDef then :funcs
          when NodeDef then :nodes
          when TypeDef then :types
          when InfixDef then :infixes
          when PrimTypeDef then :ptypes
          when PrimFuncDef then :pfuncs
          end
          t[k] << d
        end
        t
      end
    end

    parser :material_file do
      seq(
        many(ws),
        symbol("material").err("material-file", "keyword 'material'").name(:keyword1),
        many1(ws),
        ident_begin_upper.name(:name),
        opt_fail(
          many1(ws) >
          symbol("use") >
          many1(ws) >
          many1_fail(load_path, comma_separator) <
          many1(ws),
        ).to_nil.name(:uses),
        many(ws),
        many_fail(material_top_def, many(ws)).name(:defs),
        many(ws),
        end_of_input.err("module", "valid end of file")
      ).map do |x|
        t = Top.new(:uses => x[:uses])
        x[:defs].each do |d|
          k = case d
          when DataDef then :datas
          when FuncDef then :funcs
          when TypeDef then :types
          when InfixDef then :infixes
          when PrimTypeDef then :ptypes
          when PrimFuncDef then :pfuncs
          end
          t[k] << d
        end
        t
      end
    end

    parser :load_path do
      many1(ident_begin_upper, str("."))
    end

    parser :input_def do
      seq(
        var_name.name(:name),
        opt_fail(
          symbol("(") > exp < symbol(")")
        ).to_nil.name(:init_exp),
        many(ws),
        str(":"),
        many(ws),
        type.err("param-def", "type").name(:type)
      ).map do |x|
        InputDef.new(x.to_h)
      end
    end

    parser :output_def do
      seq(
        var_name.name(:name),
        many(ws),
        str(":"),
        many(ws),
        type.err("param-def", "type").name(:type)
      ).map do |x|
        OutputDef.new(x.to_h)
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
        str("="),
        many(ws),
        exp.err("data-def", "valid expression").name(:exp),
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
        str("="),
        many(ws),
        exp.err("func-def", "valid expression").name(:exp),
        end_of_def.err("func-def", "valid end of func-def")
      ).map do |x|
        FuncDef.new(x.to_h)
      end
    end

    parser :node_def do # -> NodeDef
      seq(
        symbol("node").name(:keyword),
        opt(many1(ws) > init_def).to_nil.name(:init_exp),
        many1(ws),
        node_instance_name.err("node-def", "node name").name(:name),
        many(ws),
        str("("),
        many_fail(node_ref, comma_separator).err("node-def", "list of param for node").name(:params),
        str(")"),
        opt_fail(
          many(ws) > str(":") > many(ws) > type.err("node-def", "[Type] after :")
        ).to_nil.name(:type),
        many(ws),
        str("="),
        many(ws),
        exp.err("node-def", "body").name(:exp),
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

    parser :primtype_def do
      seq(
        symbol("primtype").name(:keyword),
        many1(ws),
        type_symbol.err("primtype-def", "type symbol to be define").name(:name),
        many(ws),
        str("=").err("primtype-def", "'='"),
        many(ws),
        many1(foreign_exp, comma_separator).err("primtype-def", "foreign-definitions").name(:foreigns),
        end_of_def.err("primtype-def", "valid end of primtype-def")
      ).map do |x|
        PrimTypeDef.new(x.to_h)
      end
    end

    parser :primfunc_def do
      seq(
        symbol("primfunc").name(:keyword),
        many1(ws),
        (func_name | operator).err("primfunc-def", "name of primfunc").name(:name),
        many(ws),
        str("("),
        many1_fail(primfunc_param_def, comma_separator).err("primfunc-def", "list of param for function").name(:params),
        str(")"),
        many(ws),
        str(":"),
        many(ws),
        type_with_var.err("func-def", "type of return value").name(:type),
        many(ws),
        str("=").err("primfunc-def", "'='"),
        many(ws),
        many1(foreign_exp, comma_separator).err("primfunc-def", "foreign-definitions").name(:foreigns),
        end_of_def.err("primfunc-def", "valid end of primfunc-def")
      ).map do |x|
        PrimFuncDef.new(x.to_h)
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

    parser :primfunc_param_def do # -> ParamDef
      seq(
        var_name.name(:name),
        many(ws),
        str(":"),
        many(ws),
        type_with_var.err("param-def", "type with type-var").name(:type)
      ).map do |x|
        ParamDef.new(x.to_h)
      end
    end


    # Body associated
    # --------------------

    parser :foreign_exp do
      seq(
        ident_begin_lower.name(:language),
        symbol("{").name(:keyword1),
        many(ws),
        many1(notchar("}")).name(:items),
        str("}").err("body-def", "'}' after c-expression").name(:keyword2)
      ).map do |x|
        ForeignExp.new(
          :language => x[:language],
          :keyword1 => x[:keyword1],
          :keyword2 => x[:keyword2],
          :desc => x[:items].map(&:item).join.strip,
          :start_pos => x[:items][0].tag,
          :end_pos => x[:items][-1].tag
        )
      end
    end

    # Node associated
    # --------------------

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
        x[:exp]
      end
    end

    parser :node_ref do
      node_name_last | node_name_current
    end

    parser :node_name_last do
      seq(
        node_instance_name.name(:name),
        symbol("@last").name(:keyword),
        opt_fail(many(ws) > str("as") > many(ws) > var_name.err("node-parameter", "name as exposed")).to_nil.name(:as)
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
        opt_fail(many(ws) > str("as") > many(ws) > var_name.err("node-parameter", "name as exposed")).to_nil.name(:as)
      ).map do |x|
        NodeRef.new(:last => false, :as => x[:as] || x[:name], :name => x[:name])
      end
    end

    # Type associated
    # --------------------

    parser :type_with_args do |inner|
      seq(
        type_symbol.name(:name),
        symbol("[").name(:keyword1),
        many1_fail(inner, comma_separator).err("type", "list of type").name(:args),
        symbol("]").err("type", "']'").name(:keyword2)
      ).map do |x|
        Type.new(x.to_h)
      end
    end

    parser :type_without_args do
      type_symbol.map do |x|
        Type.new(:name => x, :args => [])
      end
    end

    parser :type_tuple do |inner|
      seq(
        symbol("(").name(:keyword1),
        many1_fail(inner, comma_separator).err("type", "list of type").name(:args),
        symbol(")").err("type", "')'").name(:keyword2)
      ).map do |x|
        type_name = SSymbol.new(:desc => "Tuple" + x[:args].size.to_s)
        Type.new(x.to_h, :name => type_name)
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
      type_with_args(type) ^ type_tuple(type) ^ type_without_args
    end

    parser :type_with_var do
      type_with_args(type_with_var) ^ type_tuple(type_with_var) ^ type_without_args ^ type_var
    end

    parser :type_with_param do
      type_with_args(type_var) ^ type_tuple(type_var) ^ type_without_args
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
