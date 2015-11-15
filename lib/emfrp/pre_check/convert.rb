module Emfrp
  module PreCheck
    def convert(top)
      convert_blockexp_into_matchexp(top)
      convert_ifexp_into_matchexp(top)
    end

    def convert_blockexp_into_matchexp(syntax)
      case syntax
      when Syntax
        syntax.each do |k, v|
          if v.is_a?(BlockExp)
            alt = v[:assigns].reverse.inject(v[:exp]) do |acc, a|
              c = Case.new(:pattern => a[:pattern], :exp => acc)
              MatchExp.new(:cases => [c], :exp => a[:exp])
            end
            syntax[k] = alt
          end
        end
        convert_blockexp_into_matchexp(syntax.values)
      when Array
        syntax.each{|x| convert_blockexp_into_matchexp(x)}
      end
    end

    def convert_ifexp_into_matchexp(syntax)
      case syntax
      when Syntax

      when Array

      end
    end
  end
end
