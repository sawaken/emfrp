module Emfrp
  module NodeCheck
    extend self
    
    def node_check(top)
      top[:nodes].each do |n|
        n[:params].each do |node_ref|
          if node_ref.is_a?(NodeRef) && node_ref[:last]
            depended_node = (top[:nodes] + top[:inputs]).select{|x| x[:name] == node_ref[:name]}.first
            unless depended_node[:init_exp]
              PreConvert.err("Node `#{node_ref[:name][:desc]}` having no init-exp is referred with @last:\n", node_ref)
            end
          end
        end
      end
      top[:nodes].each do |n|
        n[:mark] = false
        n[:prev] = nil
      end
      top[:nodes].each do |n|
        circular_check(top[:nodes], top[:inputs], n)
      end
      top[:nodes].each do |n|
        n.delete(:mark)
        n.delete(:prev)
      end
    end

    def circular_check(nodes, inputs, node)
      node[:mark] = true
      node[:params].each do |x|
        if x.is_a?(NodeRef) && !x[:last] && !inputs.find{|i| i[:name] == x[:name]}
          depended_node = nodes.select{|y| y[:name] == x[:name]}.first
          unless depended_node
            PreConvert.err("Undefined node `#{x[:as][:desc]}` is referred:\n", x)
          end
          if depended_node[:mark] == true
            trace = ([x] + get_trace(node)).reverse
            s = "[#{trace.rotate(-1).map{|x| "`#{x[:name][:desc]}`"}.join(" -> ")} -> ...]"
            PreConvert.err("Circular node-dependency #{s} is detected.\n", *trace)
          end
          depended_node[:prev] = node
          circular_check(nodes, inputs, depended_node)
        end
      end
      node[:mark] = false
    end

    def get_trace(node)
      trace = []
      n = node
      until n[:prev] == nil || trace.include?(n)
        ref = n[:prev][:params].find{|param| param.is_a?(NodeRef) && param[:as] == n[:name]}
        trace << ref
        n = n[:prev]
      end
      return trace
    end
  end
end
