module Emfrp
  module Convert
    def calc_allocs(top)
      top[:nodes].each do |node_def|
        calc_allocs_exp(node_def[:init_exp]) if node_def[:init_exp]
        calc_allocs_exp(node_def[:exp])
      end
      top[:inputs].each do |input_def|
        calc_allocs_exp(input_def[:init_exp]) if input_def[:init_exp]
      end
    end

    def calc_allocs_exp(exp)
      if exp.has_key?(:allocs)
        return exp[:allocs]
      end
      case exp
      when MatchExp
        res = {}
        exp[:cases].each do |c|
          res = select_merge(res, calc_allocs_exp(c[:exp]))
        end
        return exp[:allocs] = res
      when FuncCall
        res = {}
        exp[:args].each do |a|
          res = add_merge(res, calc_allocs_exp(a))
        end
        if exp[:func].get.is_a?(FuncDef)
          return exp[:allocs] = add_merge(res, calc_allocs_exp(exp[:func].get[:exp]))
        else
          return exp[:allocs] = res
        end
      when ValueConst
        res = {}
        exp[:args].each do |a|
          res = add_merge(res, calc_allocs_exp(a))
        end
        return exp[:allocs] = add_merge(res, {exp[:type] => 1})
      when Syntax
        return exp[:allocs] = {}
      end
    end

    def select_merge(a, b)
      a.merge(b){|k, v1, v2| [v1, v2].max}
    end

    def add_merge(a, b)
      a.merge(b){|k, v1, v2| v1 + v2}
    end
  end
end
