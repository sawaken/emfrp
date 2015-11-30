module Emfrp
  module Convert
    def node_sort(top)
      serial = (0..100).to_a
      input_names = top[:inputs].map{|x| x[:name]}
      pool = top[:nodes].map{|n| [n, n[:params].reject{|x| x[:last]}.map{|x| x[:name]}]}
      pool.each{|x, dep| dep.reject!{|y| input_names.include?(y)}}
      until pool.empty?
        pool.sort!{|a, b| a[1].size <=> b[1].size}
        n, dep = *pool.shift
        raise "assertion error" unless dep == []
        n[:order] = serial.shift
        pool.each{|x, dep| dep.reject!{|y| y == n[:name]}}
      end
      top[:nodes].sort!{|a, b| a[:order] <=> b[:order]}
      calc_die_point(top)
    end

    def calc_die_point(top)
      nsize = top[:nodes].size
      top[:nodes].each_with_index do |n1, i|
        die_points = [0]
        top[:nodes].each_with_index do |n2, j|
          n2[:params].each do |param|
            if param[:name] == n1[:name]
              if param[:last]
                die_points << (j - i) + nsize
              else
                die_points << j - i
              end
            end
          end
        end
        n1[:die_point] = die_points.max
      end
    end
  end
end
