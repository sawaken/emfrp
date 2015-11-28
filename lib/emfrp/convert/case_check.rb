module Emfrp
  module Convert
    def case_check(syntax)
      case syntax
      when MatchExp
        check_patterns_comprehensive(syntax[:cases].map{|c| c[:pattern]})
        case_check(syntax.values)
      when Syntax
        case_check(syntax.values)
      when Array
        syntax.each{|x| case_check(x)}
      end
    end

    def check_patterns_comprehensive(patterns)

    end
  end
end
