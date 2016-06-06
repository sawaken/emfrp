module Emfrp
  module NewNodeConvert
    extend self

    def parse_module(mod_name, newnode, file_loader)
      src_str, file_name = file_loader.load(newnode[:module_path].map{|x| x[:desc]})
      top = Parser.parse_src(src_str, file_name, file_loader)
      uniq_key = "#{mod_name}(#{newnode[:names].map{|x| x[:desc]}.join(",")})"
      rename_nodes(top, uniq_key)
      top[:inputs].zip(newnode[:args]).each do |input, arg_exp|
        input[:name][:desc] << "##{uniq_key}"
        top[:nodes] << NodeDef.new(
          :name => input[:name],
          :init_exp => nil,
          :params => nil,
          :type => nil,
          :exp => arg_exp,
        )
      end
      top[:inputs] = []
      top[:outputs].zip(newnode[:names]).each do |output, newnode_name|
        output[:name][:desc] << "##{uniq_key}"
        top[:nodes] << NodeDef.new(
          :name => newnode_name,
          :init_exp => nil,
          :params => nil,
          :type => nil,
          :exp => VarRef.new(:name => output[:name])
        )
      end
      top[:outputs] = []
      return top
    end

    def rename_nodes(top, uniq_key)
      datas = Hash[top[:datas].map{|x| [x[:name][:desc], true]}]
      top[:nodes].each do |n|
        white_list = {}
        n[:name][:desc] << "##{uniq_key}"
        if n[:params]
          n[:params].each do |pn|
            white_list[pn[:as][:desc].clone] = true
            pn[:name][:desc] << "##{uniq_key}"
            pn[:as][:desc] << "##{uniq_key}"
          end
        end
        rename_node_exp(n[:exp], datas, white_list, uniq_key, {})
      end
    end

    def rename_node_exp(exp, datas, white_list, uniq_key, local_vars)
      case exp
      when VarRef
        name = exp[:name][:desc]
        if !local_vars[name] && (white_list[name] || !datas[name])
          if name =~ /^(.*)@last$/
            exp[:name][:desc] = "#{$1}##{uniq_key}@last"
          else
            exp[:name][:desc] << "##{uniq_key}"
          end
        end
      when Case
        vs = Hash[exp[:pattern].find_refs.map{|x| [x[:desc], true]}]
        rename_node_exp(exp[:exp], datas, white_list, uniq_key, local_vars.merge(vs))
      when Syntax
        rename_node_exp(exp.values, datas, white_list, uniq_key, local_vars)
      when Array
        exp.each{|e| rename_node_exp(e, datas, white_list, uniq_key, local_vars)}
      end
    end
  end
end
