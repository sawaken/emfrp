module Emfrp
  module CodeGen
    class C
      module Naming
        extend self

        def naming(top)
          type_naming(top)
          func_naming(top)
          data_naming(top)
          node_naming(top)
        end

        def type_naming(top)
          top[:itypes].each do |type_def|
            if type_def[:tvalues].all?{|x| x[:params].length == 0}
              type_def[:cstruct_name] = nil
              type_def[:ctype_ref] = "int"
              type_def[:tvalues].each_with_index do |t, i|
                t[:cvalue] = i.to_s
              end
            else
              type_def[:cstruct_name] = type_def[:type][:name][:desc]
              type_def[:ctype_ref] = "struct " + type_def[:cstruct_name] + (type_def[:static] ? "" : "*")
              type_def[:tvalues].each do |t|
                t[:cfunc_name] = t[:name][:desc]
                t[:params].each_with_index do |p, i|
                  p[:cvar_name] = "member#{i}"
                end
              end
            end
          end
          top[:ptypes].each do |t|
            ctype_foreign = t[:foreigns].find{|x| x[:language][:desc] == "c"}
            raise "assertion error: foreign for c is undefined in #{t[:name][:desc]}" unless ctype_foreign
            t[:ctype_ref] = ctype_foreign[:desc]
          end
        end

        def func_naming(top)
          top[:ifuncs].each do |func_def|
            func_def[:cfunc_name] = name2cname(func_def[:name][:desc])
          end
          top[:pfuncs].each do |func_def|
            func_def[:cfunc_name] = name2cname(func_def[:name][:desc])
          end
        end

        def data_naming(top)
          top[:datas].each do |data_def|
            data_def[:cvar_name] = "data_" + data_def[:name][:desc]
            data_def[:cinitfunc_name] = "init_data_" + data_def[:name][:desc]
          end
        end

        def node_naming(top)
          top[:nodes].each do |node_def|
            node_def[:cfunc_name] = "node_" + node_def[:name][:desc]
            node_def[:params].each do |p|
              p[:cvar_name] = name2cname(p[:as][:desc])
            end
          end
        end

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
          "~" => "_tilde_"
        }
        def name2cname(name)
          rexp = Regexp.new("[" + Regexp.escape(SymbolToStr.keys.join) + "]")
          name.gsub(rexp, SymbolToStr)
        end
      end
    end
  end
end
