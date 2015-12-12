module Emfrp
  module Graphviz
    extend self

    def compile(top, output_io)
      node_stmts, edge_stmts = [], []
      visited = {}
      top[:outputs].each do |n|
        node = top[:dict][:node_space][n[:name][:desc]].get
        traverse(top, node, node_stmts, edge_stmts, true, visited)
      end
      output_io << "digraph positioner {\n"
      node_stmts.each do |s|
        output_io << "  #{s}\n"
      end
      edge_stmts.each do |s|
        output_io << "  #{s}\n"
      end
      output_io << "}\n"
    end

    def traverse(top, node, node_stmts, edge_stmts, is_output, visited)
      return if visited[node]
      visited[node] = true
      name = node[:name][:desc]
      type = node[:typing].to_uniq_str
      node_attrs = ["label = \"#{name} : #{type}\""]
      node_attrs += ["style = filled", "fillcolor = \"#e4e4e4\""] if is_output
      case node
      when NodeDef
        node[:params].each do |n|
          ch_name = n[:name][:desc]
          if n[:last]
            edge_stmts << "#{ch_name} -> #{name} [style = dashed];"
          else
            edge_stmts << "#{ch_name} -> #{name};"
          end
          ch_node = top[:dict][:node_space][ch_name].get
          traverse(top, ch_node, node_stmts, edge_stmts, false, visited)
        end
      when InputDef
        node_attrs << "shape = \"invhouse\""
      end
      node_stmts << "#{name} [#{node_attrs.join(", ")}];"
    end
  end
end
