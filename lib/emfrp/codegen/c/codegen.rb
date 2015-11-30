require 'emfrp/codegen/c/naming'
require 'emfrp/codegen/c/calc_memory'

module Emfrp
  module CodeGen
    class C
      def initialize(top)
        @top = top
        @type_tbl = (top[:itypes].map{|x| [x[:type][:name][:desc], x]} + top[:ptypes].map{|x| [x[:name][:desc], x]}).to_h
        @structs = []
        @consts = []
        @funcs = []
        @macros = []
        @gvardec = []
        @initstmts = []
        @protos = []
      end

      def compile
        Naming.naming(@top)
        type_gen(@top)
        func_gen(@top)
        data_gen(@top)
        node_gen(@top)
        node_var_gen(@top)
        memory_gen(@top)
        main_gen(@top)
      end

      def out(output_io)
        xs = @macros + @structs + @protos + @gvardec + @consts + @funcs
        output_io << xs.map(&:to_s).join("\n") + "\n"
      end

      def tref(utype)
        raise "assertion error: non-monomorphic type #{utype.to_uniq_str}" if utype.typeargs.size > 0
        @type_tbl[utype.to_uniq_str][:ctype_ref]
      end

      def memory_gen(top)
        max_memory = CalcMemory.calc_memory(top)
        max_memory.each do |t, i|
          tn = t.get[:type][:name][:desc]
          @gvardec << "struct #{t.get[:cstruct_name]} memory_#{tn}[#{i}];"
          @gvardec << "int count_#{tn} = #{i};"
          @gvardec << "int itr_#{tn} = 0;"
        end
        @gvardec << "int counter = 1;"
        @gvardec << "int N = #{top[:nodes].size};"
        @funcs << Cfunc("void", "reloadMark", []) do |x|
          x << "int i;"
          max_memory.each do |t, i|
            tn = t.get[:type][:name][:desc]
            mn = "memory_#{tn}[i].mark"
            stmts = []
            stmts << "if (#{mn} < counter) #{mn} = 0;"
            stmts << "else #{mn} -= counter - 1;"
            x << Block.new("for (i = 0; i < count_#{tn}; i++) {", stmts, "}")
          end
        end
      end

      def main_gen(top)
        @funcs << Cfunc("void", "Activate" + @top[:module_name][:desc], [], "true") do |x|
          @initstmts.each do |i|
            x << i
          end
          x << "int current_side = 0, last_side = 1;"
          stmts = []
          stmts << "counter = 1;"
          input_types = top[:inputs].map{|x| tref(x[:mono_typing]) + "*"}
          @protos << "extern void Input(#{input_types.join(", ")});"
          inputs = top[:inputs].map{|x| "&value_node_#{x[:name][:desc]}[current_side]"}.join(", ")
          stmts << "Input(#{inputs});"
          @top[:nodes].each do |n|
            args = n[:params].map{|x| "value_node_#{x[:name][:desc]}[#{x[:last] ? "last_side" : "current_side"}]"}
            output_arg = "&value_node_#{n[:name][:desc]}[current_side]"
            stmts << "#{n[:cfunc_name]}(#{(args + [output_arg]).join(", ")});"
            t = @type_tbl[n[:mono_typing].to_uniq_str]
            if t.is_a?(TypeDef)
              tn = t[:type][:name][:desc]
              stmts << "mark_#{tn}(value_node_#{n[:name][:desc]}[current_side], counter + #{n[:die_point]});"
            end
            stmts << "counter++;"
          end
          output_types = top[:outputs].map{|x| tref(top[:nodes].find{|y| y[:name] == x[:name]}[:mono_typing]) + "*"}
          @protos << "extern void Output(#{output_types.join(", ")});"
          outputs = top[:outputs].map{|x| "&value_node_#{x[:name][:desc]}[current_side]"}.join(", ")
          stmts << "Output(#{outputs});"
          stmts << "reloadMark();"
          stmts << "current_side ^= 1;"
          stmts << "last_side ^= 1;"
          x << Block.new("while (1) {", stmts, "}")
        end
      end

      def type_gen(top)
        top[:itypes].each do |type_def|
          next unless type_def[:cstruct_name]
          @structs << Cstruct(type_def[:cstruct_name], nil) do |x|
            x << "int tvalue_id;" if type_def[:tvalues].length > 1
            x << "int mark;" unless type_def[:static]
            x << Cunion(nil, "value") do |y|
              type_def[:tvalues].each_with_index do |tvalue, i|
                params = tvalue[:params].map{|param| [tref(param[:mono_typing]), param[:cvar_name]]}
                @consts << Cfunc(tref(type_def[:mono_typing]), tvalue[:cfunc_name], params) do |z|
                  mname = "memory_#{type_def[:type][:name][:desc]}"
                  cname = "count_#{type_def[:type][:name][:desc]}"
                  iname = "itr_#{type_def[:type][:name][:desc]}"
                  while_stmts = []
                  while_stmts << "#{iname}++;"
                  while_stmts << "#{iname} %= #{cname};"
                  mn = "#{mname}[#{iname}].mark"
                  while_stmts << "if (#{mn} < counter) { x = #{mname} + #{iname}; break; }"
                  z << "#{tref(type_def[:mono_typing])} x;"
                  z << Block.new("while (1) {", while_stmts, "}")
                  z << "x->tvalue_id = #{i};" if type_def[:tvalues].length > 1
                  tvalue[:params].each do |param|
                    z << "x->value.#{tvalue[:name][:desc]}.#{param[:cvar_name]} = #{param[:cvar_name]};"
                  end
                  z << "return x;"
                end
                next if tvalue[:params].size == 0
                y << Cstruct(nil, tvalue[:name][:desc]) do |z|
                  tvalue[:params].each do |param|
                    z << "#{tref(param[:mono_typing])} #{param[:cvar_name]};"
                  end
                end
              end
            end
            params = [[tref(type_def[:mono_typing]), "x"], ["int", "mark"]]
            @funcs << Cfunc("void", "mark_" + type_def[:cstruct_name], params) do |x|
              x << "x->mark = mark;" unless type_def[:static]
              accessor = type_def[:static] ? "." : "->"
              cases = []
              type_def[:tvalues].each_with_index do |tvalue, i|
                calls = []
                tvalue[:params].each_with_index do |param, i|
                  param_type_name = param[:mono_typing].to_uniq_str
                  if @type_tbl[param_type_name].is_a?(TypeDef)
                    calls << "mark_#{param_type_name}(x#{accessor}value.#{tvalue[:name][:desc]}.member#{i}, mark);"
                  end
                end
                cases << "case #{i}: #{calls.join(" ")} break;" if calls.size > 0
              end
              if cases.size > 0
                switch_exp = type_def[:tvalues].size == 1 ? "0" : "x#{accessor}tvalue_id"
                x << Block.new("switch (#{switch_exp}) {", cases, "}")
              end
            end
          end
        end
      end

      def func_gen(top)
        top[:ifuncs].each do |func_def|
          next unless func_def.has_key?(:used) && func_def[:used]
          params = func_def[:params].map{|x| [tref(x[:mono_typing]), x[:name][:desc]]}
          @funcs << Cfunc(tref(func_def[:mono_typing].typeargs.last), func_def[:cfunc_name], params) do |x|
            x << "return #{exp_gen(func_def[:exp], x)};"
          end
        end
        top[:pfuncs].each do |func_def|
          next unless func_def.has_key?(:used) && func_def[:used]
          params_str = func_def[:params].map{|x| x[:name][:desc]}.join(", ")
          exp = func_def[:foreigns].find{|x| x[:language][:desc] == "c"}
          raise "assertion error: foreign for c is undefined in #{func_def[:name][:desc]}" unless exp
          @macros << "#define #{func_def[:cfunc_name]}(#{params_str}) (#{exp[:desc]})"
        end
      end

      def data_gen(top)
        top[:datas].each do |data_def|
          next unless data_def.has_key?(:used) && data_def[:used]
          t = tref(data_def[:mono_typing])
          vn = data_def[:cvar_name]
          fn = data_def[:cinitfunc_name]
          @gvardec << "#{t} #{vn};"
          @initstmts << "#{vn} = #{fn}();"
          @funcs << Cfunc(t, fn, []) do |x|
            x << "return #{exp_gen(data_def[:exp], x)};"
          end
        end
      end

      def node_gen(top)
        top[:nodes].each do |node_def|
          params = node_def[:params].map{|x| [tref(x[:mono_typing]), x[:cvar_name]]}
          output_param = [tref(node_def[:mono_typing]) + "*", "output"]
          @funcs << Cfunc("int", node_def[:cfunc_name], params + [output_param]) do |x|
            e = exp_gen(node_def[:exp], x)
            x << "*output = #{e};"
            x << "return 1;"
          end
        end
      end

      def node_var_gen(top)
        (top[:nodes] + top[:inputs]).each do |d|
          name = d[:name][:desc]
          type = tref(d[:mono_typing])
          @gvardec << "#{type} value_node_#{name}[2];"
          if d[:init_exp]
            @initstmts << "value_node_#{name}[1] = init_node_#{name}();"
            tn = d[:mono_typing].to_uniq_str
            if @type_tbl[tn].is_a?(TypeDef)
              pos = top[:nodes].index{|x| x[:name] == d[:name]}
              @initstmts << "mark_#{tn}(value_node_#{name}[1], #{pos + 1} + #{d[:die_point]});"
            end
            @funcs << Cfunc(type, "init_node_#{name}", []) do |x|
              x << "return #{exp_gen(d[:init_exp], x)};"
            end
          end
        end
        @initstmts << "counter = #{top[:nodes].size + 1};"
        @initstmts << "reloadMark();"
      end

      def exp_gen(exp, stmts, serial=(0..100).to_a)
        case exp
        when FuncCall
          args = exp[:args].map{|x| exp_gen(x, stmts, serial)}
          return "#{exp[:func].get[:cfunc_name]}(#{args.join(", ")})"
        when ValueConst
          args = exp[:args].map{|x| exp_gen(x, stmts, serial)}
          return "#{exp[:name][:desc]}(#{args.join(", ")})"
        when LiteralIntegral
          exp[:entity][:desc]
        when VarRef
          exp[:name][:desc]
        when MatchExp
          v = "_tmp%03d" % serial.shift
          stmts << "#{tref(exp[:mono_typing])} #{v};"
          match_exp_gen(exp, v, stmts, serial)
          return v
        else
          raise "assertion error: unexpected type #{exp.class}"
        end
      end

      def match_exp_gen(match, vname, stmts, serial)
        left = match[:exp]
        if left.is_a?(VarRef)
          left_vname = left[:name][:desc]
        else
          left_vname = "_tmp%03d" % serial.shift
          stmts.unshift "#{tref(left[:mono_typing])} #{left_vname};"
          stmts.push "#{left_vname} = #{exp_gen(left, stmts, serial)};"
        end
        match[:cases].each_with_index do |c, i|
          then_stmts = []
          cond_exps = pattern_to_cond_exps(left_vname, then_stmts, c[:pattern])
          cond_exp = cond_exps.size == 0 ? "1" : cond_exps.join(" && ")
          if c[:exp].is_a?(SkipExp)
            then_stmts << "return 0;"
          else
            then_stmts << "#{vname} = #{exp_gen(c[:exp], then_stmts, serial)};"
          end
          if i == 0
            stmts << Block.new("if (#{cond_exp}) {", then_stmts, "}")
          else
            stmts << Block.new("else if (#{cond_exp}) {", then_stmts, "}")
          end
        end
      end

      def pattern_to_cond_exps(receiver, stmts, pattern)
        if pattern[:ref]
          stmts << "#{tref(pattern[:mono_typing])} #{pattern[:ref][:desc]} = #{receiver};"
        end
        case pattern
        when ValuePattern
          conds = []
          type_def = pattern[:type].get
          accessor = type_def[:static] ? "." : "->"
          if type_def[:tvalues].size > 1
            tvalue_id = type_def[:tvalues].index{|x| x[:name] == pattern[:name]}
            if type_def[:cstruct_name]
              conds << "#{receiver}" + accessor + "tvalue_type == " + tvalue_id.to_s
            else
              conds << "#{receiver} == #{tvalue_id}"
            end
          end
          new_receiver = "#{receiver}" + accessor + "value." + pattern[:name][:desc]
          pattern[:args].each_with_index do |x, i|
            conds += pattern_to_cond_exps(new_receiver + ".member#{i}", stmts, x)
          end
          return conds
        when IntegralPattern
          return ["#{receiver} == #{pattern[:val][:entity][:desc]}"]
        else
          return []
        end
      end

      def Cstruct(def_name, var_name, &proc)
        elements = []
        proc.call(elements)
        Block.new("struct #{def_name}{", elements, "}#{var_name};")
      end

      def Cunion(def_name, var_name, &proc)
        elements = []
        proc.call(elements)
        Block.new("union #{def_name}{", elements, "}#{var_name};")
      end

      def Cfunc(type_ref, func_name, params, expose=false, &proc)
        elements = []
        proc.call(elements)
        deco = expose ? "" : "static "
        @protos << "#{deco}#{type_ref} #{func_name}(#{params.map{|a, b| "#{a}"}.join(", ")});"
        Block.new("#{deco}#{type_ref} #{func_name}(#{params.map{|a, b| "#{a} #{b}"}.join(", ")}) {", elements, "}")
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
end
