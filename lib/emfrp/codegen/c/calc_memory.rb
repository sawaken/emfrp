
module Emfrp
  module CodeGen
    class C
      module CalcMemory
        extend self
        INF = 10000
        def calc_memory(top, log=STDERR)
          type_tbl = top[:itypes].map{|x| [x[:type][:name][:desc], x]}.to_h
          max_memory = {}
          using_datas = []
          top[:datas].each do |d|
            loging(using_datas, d[:exp], log)
            using_memory = using_datas.map{|x| x[0]}.inject({}){|acc, t| Convert.add_merge(acc, t[:allocs])}
            max_memory = Convert.select_merge(max_memory, Convert.add_merge(using_memory, d[:exp][:allocs]))
            using_datas << [type_tbl[d[:mono_typing].to_flatten_uniq_str], d[:name][:desc], INF] if type_tbl[d[:mono_typing].to_flatten_uniq_str]
          end
          2.times do
            top[:nodes].each do |n|
              loging(using_datas, n[:exp], log)
              using_memory = using_datas.map{|x| x[0]}.inject({}){|acc, t| Convert.add_merge(acc, t[:allocs])}
              if n[:init_exp]
                allocs = Convert.select_merge(n[:init_exp][:allocs], n[:exp][:allocs])
              else
                allocs = n[:exp][:allocs]
              end
              max_memory = Convert.select_merge(max_memory, Convert.add_merge(using_memory, allocs))
              using_datas << [type_tbl[n[:mono_typing].to_flatten_uniq_str], n[:name][:desc], n[:die_point]] if type_tbl[n[:mono_typing].to_flatten_uniq_str]
              using_datas.map!{|a, b, c| [a, b, c-1]}
              using_datas.reject!{|a, b, c| c < 0}
            end
          end
          return max_memory
        end

        def loging(using_datas, exp, log)

          ds = using_datas.map{|a, b, c| a[:type][:name][:desc] + " : " + b}.join(", ")
          log << "retaining #{ds}, calc exp(#{exp[:allocs]})\n"
        end

      end
    end
  end
end
