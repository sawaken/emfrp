require 'emfrp/syntax'
require 'emfrp/compile/c/syntax_exp_codegen'

module Emfrp
  class Top
    def codegen(ct, ar)
      self[:dict][:itype_space].each do |k, v|
        v.get.struct_gen(ct)
        v.get.constructor_gen(ct)
        v.get.marker_gen(ct)
      end
      self[:inputs].each do |i|
        if i[:init_exp]
          i.init_func_gen(ct)
          ct.define_init_stmt "#{i.node_var_name(ct)}[last_side] = #{i.init_func_name(ct)}();"
        end
        i.node_var_gen(ct)
      end
      self[:dict][:sorted_nodes].each_with_index do |n, i|
        node = n.get
        node.func_gen(ct)
        node.node_var_gen(ct)
        if node[:init_exp]
          node.init_func_gen(ct)
          ct.define_init_stmt "#{node.node_var_name(ct)}[last_side] = #{node.init_func_name(ct)}();"
          t = ct.tdef(node)
          if t.is_a?(TypeDef)
            ct.define_init_stmt "#{t.marker_func_name(ct)}(#{node.node_var_name(ct)}[last_side], #{i + 1} + #{ar.life_point(node)});"
          end
        end
      end
      self[:dict][:ifunc_space].each do |k, v|
        v.get.codegen(ct)
      end
      self[:dict][:used_pfuncs].each do |v|
        v.get.codegen(ct)
      end
      self[:dict][:sorted_datas].each do |v|
        v.get.codegen(ct)
      end
      memory_gen(ct, ar)
      main_gen(ct, ar)
      io_proto_gen(ct)
    end

    def memory_gen(ct, ar)
      max_memory = ar.requirement()
      max_memory.each do |t, i|
        t = t.get
        next if t[:static] || t.enum?(ct)
        ct.define_global_var("struct #{t.struct_name(ct)}", "#{t.memory_name(ct)}[#{i}]")
        ct.define_global_var("int", "#{t.memory_size_name(ct)}", "#{i}")
        ct.define_global_var("int", "#{t.memory_counter_name(ct)}", "0")
      end
      ct.define_global_var("int", "Counter", "1")
      ct.define_global_var("int", "NodeSize", "#{self[:dict][:sorted_nodes].size}")
      ct.define_func("void", "refreshMark", []) do |x|
        x << "int i;"
        max_memory.each do |t, i|
          t = t.get
          mn = "#{t.memory_name(ct)}[i].mark"
          stmts = []
          stmts << "if (#{mn} < Counter) #{mn} = 0;"
          stmts << "else #{mn} -= Counter - 1;"
          x << ct.make_block("for (i = 0; i < #{t.memory_size_name(ct)}; i++) {", stmts, "}")
        end
      end
    end

    def main_gen(ct, ar)
      ct.define_func("void", "Activate" + self[:module_name][:desc], [], :none) do |x|
        x << "int current_side = 0, last_side = 1;"
        ct.define_init_stmt "Counter = NodeSize + 1;"
        ct.define_init_stmt "refreshMark();"
        ct.init_stmts.each do |i|
          x << i
        end
        stmts = []
        stmts << "Counter = 1;"
        inputs = self[:inputs].map{|x| "&#{x.node_var_name(ct)}[current_side]"}.join(", ")
        stmts << "Input(#{inputs});"
        self[:dict][:sorted_nodes].each do |n|
          node = n.get
          args = node[:params].map do |x|
            pn = self[:dict][:node_space][x[:name][:desc]].get
            "#{pn.node_var_name(ct)}[#{x[:last] ? "last_side" : "current_side"}]"
          end
          output_arg = "&#{node.node_var_name(ct)}[current_side]"
          stmts << "#{node.node_func_name(ct)}(#{[args, *output_arg].join(", ")});"
          t = ct.tdef(node)
          if t.is_a?(TypeDef)
            mark_val = "Counter + #{ar.life_point(node)}"
            stmts << "#{t.marker_func_name(ct)}(#{node.node_var_name(ct)}[current_side], #{mark_val});"
          end
          stmts << "Counter++;"
        end
        outputs = self[:outputs].map do |x|
          node = self[:dict][:node_space][x[:name][:desc]].get
          "&#{node.node_var_name(ct)}[current_side]"
        end
        stmts << "Output(#{outputs.join(", ")});"
        stmts << "refreshMark();"
        stmts << "current_side ^= 1;"
        stmts << "last_side ^= 1;"
        x << ct.make_block("while (1) {", stmts, "}")
      end
    end

    def io_proto_gen(ct)
      ct.define_proto("void", "Input", self[:inputs].map{|x| ct.tref(x) + "*"}, :extern)
      ct.define_proto("void", "Output", self[:outputs].map{|x| ct.tref(x) + "*"}, :extern)
    end

    def node_init_stmt_gen(ct, ar)
      (self[:nodes] + self[:inputs]).each do |d|
        d.node_var_gen(ct)
        if d[:init_exp]
          d.init_func_gen(ct)
          ct.define_init_stmt "#{d.node_var_name(ct)}[1] = #{d.init_func_name}();"
          t = ct.tdef(d)
          if t.is_a?(TypeDef)
            pos = self[:dict][:sorted_nodes].index{|x| x[:name] == d[:name]}
            ct.define_init_stmt "#{t.marker_func_name(ct)}(#{d.node_var_name(ct)}[1], #{pos + 1} + #{ar.life_point(n)});"
          end
        end
      end
      ct.define_init_stmt "Counter = #{top[:nodes].size + 1};"
      ct.define_init_stmt << "refreshMark();"
    end
  end

  class TypeDef
    def struct_gen(ct)
      return if enum?(ct)
      ct.define_struct("struct", struct_name(ct), nil) do |s1|
        s1 << "int tvalue_id;" if self[:tvalues].length > 1
        s1 << "int mark;" unless self[:static]
        s1 << ct.define_struct("union", nil, "value") do |s2|
          self[:tvalues].each_with_index do |tvalue, i|
            next if tvalue[:params].size == 0
            s2 << ct.define_struct("struct", nil, tvalue.struct_name(ct)) do |s3|
              tvalue[:params].each_with_index do |param, i|
                s3 << "#{ct.tref(param)} member#{i};"
              end
            end
          end
        end
      end
    end

    def constructor_gen(ct)
      return if enum?(ct)
      self[:tvalues].each_with_index do |tvalue, i|
        params = tvalue[:params].each_with_index.map do |param, i|
          [ct.tref(param), "member#{i}"]
        end
        ct.define_func(ref_name(ct), tvalue.constructor_name(ct), params) do |s|
          while_stmts = []
          while_stmts << "#{memory_counter_name(ct)}++;"
          while_stmts << "#{memory_counter_name(ct)} %= #{memory_size_name(ct)};"
          mn = "#{memory_name(ct)}[#{memory_counter_name(ct)}].mark"
          while_stmts << "if (#{mn} < Counter) { x = #{memory_name(ct)} + #{memory_counter_name(ct)}; break; }"
          s << "#{ref_name(ct)} x;"
          s << ct.make_block("while (1) {", while_stmts, "}")
          s << "x->tvalue_id = #{i};" if self[:tvalues].length > 1
          tvalue[:params].each_with_index do |param, i|
            s << "x->value.#{tvalue.struct_name(ct)}.member#{i} = member#{i};"
          end
          s << "return x;"
        end
      end
    end

    def marker_gen(ct)
      return if enum?(ct)
      params = [[ref_name(ct), "x"], ["int", "mark"]]
      ct.define_func("void", marker_func_name(ct), params) do |x|
        x << "x->mark = mark;" unless self[:static]
        accessor = self[:static] ? "." : "->"
        cases = []
        self[:tvalues].each_with_index do |tvalue, i|
          calls = []
          tvalue[:params].each_with_index do |param, i|
            if ct.tdef(param).is_a?(TypeDef)
              fn = ct.tdef(param).marker_func_name(ct)
              calls << "#{fn}(x#{accessor}value.#{tvalue.struct_name(ct)}.member#{i}, mark);"
            end
          end
          cases << "case #{i}: #{calls.join(" ")} break;" if calls.size > 0
        end
        if cases.size > 0
          switch_exp = self[:tvalues].size == 1 ? "0" : "x#{accessor}tvalue_id"
          x << ct.make_block("switch (#{switch_exp}) {", cases, "}")
        end
      end
    end

    def enum?(ct)
      self[:tvalues].all?{|x| x[:params].length == 0}
    end

    def struct_name(ct)
      unless enum?(ct)
        self[:tvalues][0][:typing].to_flatten_uniq_str
      else
        raise
      end
    end

    def marker_func_name(ct)
      unless enum?(ct)
        "mark_#{struct_name(ct)}"
      else
        raise
      end
    end

    def ref_name(ct)
      if enum?(ct)
        "int"
      else
        "struct " + struct_name(ct) + (self[:static] ? "" : "*")
      end
    end

    def memory_name(ct)
      "memory_#{struct_name(ct)}"
    end

    def memory_size_name(ct)
      "size_#{struct_name(ct)}"
    end

    def memory_counter_name(ct)
      "counter_#{struct_name(ct)}"
    end
  end

  class TValue
    def constructor_name(ct)
      self[:name][:desc] + "_" + ct.serial(self[:name][:desc], self).to_s
    end

    def struct_name(ct)
      self[:name][:desc]
    end
  end

  class PrimTypeDef
    def codegen(ct)
      # do nothing
    end

    def ref_name(ct)
      ctype_foreign = self[:foreigns].find{|x| x[:language][:desc] == "c"}
      unless ctype_foreign
        raise "compile error: foreign for c is undefined in #{self[:name][:desc]}"
      end
      ctype_foreign[:desc]
    end
  end

  class NodeDef
    def func_gen(ct)
      params = self[:params].map{|x| [ct.tref(x), ct.escape_name(x[:as][:desc])]}
      output_param = [ct.tref(self) + "*", "output"]
      ct.define_func("int", node_func_name(ct), params + [output_param]) do |x|
        x << "*output = #{self[:exp].codegen(ct, x)};"
        x << "return 1;"
      end
    end

    def init_func_gen(ct)
      ct.define_func(ct.tref(self), init_func_name(ct), []) do |x|
        x << "return #{self[:init_exp].codegen(ct, x)};"
      end
    end

    def node_var_gen(ct)
      ct.define_global_var(ct.tref(self), "#{node_var_name(ct)}[2]")
    end

    def init_func_name(ct)
      "init_#{self[:name][:desc]}"
    end

    def node_func_name(ct)
      "node_#{self[:name][:desc]}"
    end

    def node_var_name(ct)
      "node_memory_#{self[:name][:desc]}"
    end

    def var_suffix(ct)
      "_nvar#{ct.serial(nil, self)}"
    end

    def var_name(ct, name)
      ct.escape_name(name)
    end
  end

  class InputDef
    def init_func_gen(ct)
      ct.define_func(tref(self), init_func_name(ct), []) do |x|
        x << "return #{self[:init_exp].codegen(ct, x)};"
      end
    end

    def node_var_gen(ct)
      ct.define_global_var(ct.tref(self), "#{node_var_name(ct)}[2]")
    end

    def init_func_name(ct)
      "init_#{self[:name][:desc]}"
    end

    def node_var_name(ct)
      "node_memory_#{self[:name][:desc]}"
    end
  end

  class DataDef
    def codegen(ct)
      t = ct.tref(self)
      ct.define_global_var(t, var_name(ct))
      ct.define_init_stmt(var_name(ct), "#{init_func_name(ct)}()")
      ct.define_func(t, init_func_name(ct), []) do |x|
        x << "return #{self[:exp].codegen(ct, x)};"
      end
    end

    def var_name(ct)
      "data_#{self[:name][:desc]}"
    end

    def init_func_name(ct)
      "init_#{self[:name][:desc]}"
    end

    def var_name(ct, name)
      ct.escape_name(name)
    end
  end

  class FuncDef
    def codegen(ct)
      params = self[:params].map{|x| [ct.tref(x), x[:name][:desc]]}
      ct.define_func(ct.tref(self), func_name(ct), params) do |x|
        x << "return #{self[:exp].codegen(ct, x)};"
      end
    end

    def func_name(ct)
      ct.escape_name(self[:name][:desc]) + "_" + ct.serial(self[:name][:desc], self).to_s
    end

    def var_name(ct, name)
      ct.escape_name(name)
    end
  end

  class PrimFuncDef
    def codegen(ct)
      params = self[:params].map{|x| x[:name][:desc]}
      exp = self[:foreigns].find{|x| x[:language][:desc] == "c"}
      raise "assertion error: foreign for c is undefined in #{self[:name][:desc]}" unless exp
      ct.define_macro(func_name(ct), params, exp[:desc])
    end

    def func_name(ct)
      ct.escape_name(self[:name][:desc])
    end
  end

  class ParamDef

  end
end
