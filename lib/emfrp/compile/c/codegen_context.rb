module Emfrp
  class CodegenContext
    SymbolToStr = {
      "!" => "_exclamation_",
      "#" => "_hash_",
      "$" => "_dollar_",
      "%" => "_parcent_",
      "&" => "_anpersand",
      "*" => "_asterisk_",
      "+" => "_plus_",
      "." => "_dot_",
      "/" => "_slash_",
      "<" => "_lt_",
      "=" => "_eq_",
      ">" => "_gt_",
      "?" => "_question_",
      "@" => "_at_",
      "\\" => "_backslash_",
      "^" => "_caret_",
      "|" => "_vertial_",
      "-" => "_minus_",
      "~" => "_tilde_",
      "(" => "_cpbegin_",
      ")" => "_cpend_",
      "," => "_comma_"
    }

    def initialize(top)
      @top = top
      @global_vars = []
      @funcs = []
      @structs = []
      @protos = []
      @static_protos = []
      @macros = []
      @init_stmts = []
      @templates = []
    end

    def code_generate(c_output, h_output, main_output, name)
      #  generate header-file
      h_output << "#ifndef #{name.upcase}_H\n"
      h_output << "#define #{name.upcase}_H\n\n"
      @protos.each do |x|
        h_output.puts x.to_s
      end
      h_output << "\n#endif /* end of include guard */\n"
      # generate library-file
      c_output.puts "#include \"#{name}.h\""
      c_output.puts "/* Primitive functions (Macros) */"
      @macros.each do |x|
        c_output.puts x.to_s
      end
      c_output.puts "/* Data types */"
      @structs.each do |x|
        c_output.puts x.to_s
      end
      c_output.puts "/* Global variables */"
      @global_vars.each do |x|
        c_output.puts x.to_s
      end
      c_output.puts "/* Static prototypes */"
      @static_protos.each do |x|
        c_output.puts x.to_s
      end
      c_output.puts "/* Functions, Constructors, GCMarkers, etc... */"
      @funcs.each do |x|
        c_output.puts x.to_s
      end
      # generate main-file
      main_output << "#include \"#{name}.h\"\n\n"
      main_output << "void Input(#{@top[:inputs].map{|x| "#{tref(x)}* #{x[:name][:desc]}"}.join(", ")}) {\n  /* Your code goes here... */\n}\n"
      main_output << "void Output(#{@top[:outputs].map{|x| "#{tref(x)}* #{x[:name][:desc]}"}.join(", ")}) {\n  /* Your code goes here... */\n}\n"
      main_output << "int main() {\n  Activate#{@top[:module_name][:desc]}();\n}\n"
    end

    def init_stmts
      @init_stmts
    end

    def func_name(name, ret_utype, arg_utypes)
      case f = @top[:dict][:func_space][name].get
      when PrimFuncDef
        f.func_name(self)
      when FuncDef
        key = [ret_utype, *arg_utypes].map(&:to_uniq_str) + [name]
        @top[:dict][:ifunc_space][key].get.func_name(self)
      else
        raise "Assertion error: unexpected func type #{f.class}"
      end
    end

    def constructor_name(name, utype)
      @top[:dict][:itype_space][utype.to_uniq_str].get[:tvalues].each do |tval|
        if tval[:name][:desc] == name
          return tval.constructor_name(self)
        end
      end
      raise "Assertion error: #{name} is not found"
    end

    def escape_name(name)
      rexp = Regexp.new("[" + Regexp.escape(SymbolToStr.keys.join) + "]")
      name.gsub(rexp, SymbolToStr)
    end

    def tdef(x)
      case x
      when Typing::UnionType
        key = x.to_uniq_str
        if @top[:dict][:type_space][key] && @top[:dict][:type_space][key].get.is_a?(PrimTypeDef)
          @top[:dict][:type_space][key].get
        elsif @top[:dict][:itype_space][key]
          @top[:dict][:itype_space][key].get
        else
          raise "Assertion error: itype #{x.to_uniq_str} is undefined"
        end
      when Syntax
        tdef(x[:typing])
      else
        raise "Assertion error"
      end
    end

    def tref(x)
      tdef(x).ref_name(self)
    end

    def serial(key, id)
      @serials ||= Hash.new{|h, k| h[k] = []}
      @serials[key] << id unless @serials[key].find{|x| x == id}
      return @serials[key].index{|x| x == id}
    end

    def uniq_id_gen
      @uniq_ids ||= (0..1000).to_a
      @uniq_ids.shift
    end

    def define_global_var(type_str, name_str, initial_value_str=nil)
      @global_vars << "#{type_str} #{name_str}" + (initial_value_str ? " = #{initial_value_str}" : "") + ";"
    end

    def define_macro(name_str, params, body_str)
      @macros << "#define #{name_str}(#{params.join(", ")}) (#{body_str})"
    end

    def define_func(type_str, name_str, params, accessor=:static, with_proto=true, &block)
      elements = []
      block.call(elements)
      case accessor
      when :none then deco = ""
      when :static then deco = "static "
      end
      define_proto(type_str, name_str, params.map(&:first), accessor) if with_proto
      @funcs << Block.new("#{deco}#{type_str} #{name_str}(#{params.map{|a, b| "#{a} #{b}"}.join(", ")}) {", elements, "}")
      return nil
    end

    def define_proto(type_str, name_str, param_types, accessor=:static)
      case accessor
      when :none then deco = ""
      when :static then deco = "static "
      when :extern then deco = "extern "
      end
      proto = "#{deco}#{type_str} #{name_str}(#{param_types.join(", ")});"
      if accessor == :static || accessor == :extern
        @static_protos << proto
      else
        @protos << proto
      end
      return nil
    end

    def define_init_stmt(stmt)
      @init_stmts << stmt
    end

    def define_struct(kind_str, name_str, var_name_str, &block)
      elements = []
      block.call(elements)
      x = Block.new("#{kind_str} #{name_str}{", elements, "}#{var_name_str};")
      if name_str
        @structs << x
        return nil
      else
        return x
      end
    end

    def make_block(head_str, elements, foot_str)
      Block.new(head_str, elements, foot_str)
    end

    class Block
      T = (0..20).map{|i| "  " * i}
      def initialize(head_str, elements, foot_str)
        @head_str = head_str
        @elements = elements
        @foot_str = foot_str
      end

      def to_s(t=0)
        res = ""
        res << T[t] + @head_str + "\n"
        @elements.each do |e|
          case e
          when Block
            res << e.to_s(t+1) + "\n"
          when String
            res << T[t+1] + e + "\n"
          end
        end
        res << T[t] + @foot_str
      end
    end
  end
end
