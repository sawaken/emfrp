module Emfrp
  module PreCheck
    def check_node(top)
      top[:nodes].each do |n|
        n[:params].map{|x| x[:name]}.each do |node_ref|
          if node_ref[:last]
            depended_node = (top[:nodes] + top[:inputs]).select{|x| x[:name] == node_ref[:name]}.first
            cond = case depended_node
            when InputDef
              depended_node[:decolator].is_a?(InitDef)
            when NodeDef
              depended_node[:init]
            end
            unless cond
              err("Defining init[exp] is needed to specify @last to #{node_ref[:name]}", depended_node)
            end
          end
        end
      end
      top[:nodes].each{|n| n[:mark] = false}
      top[:nodes].each{|n| circular_check(top[:nodes], n)}
    end

    def circular_check(nodes, node)
      if n[:mark] != false
        err("Circular definition of node", n[:mark])
      end
      node[:mark] = true
      n[:params].each do |x|
        if x.is_a?(SSymbol)
          depended_nodes = nodes.select{|y| y[:name] == x[:name]}.first
          circular_check(nodes, depended_nodes)
        end
      end
      node[:mark] = false
    end
  end
end
