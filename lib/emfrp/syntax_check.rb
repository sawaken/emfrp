module Emfrp
  class SyntaxCheck
    extend self

    InvalidSyntaxOccur = Class.new(RuntimeError)

    # Utils
    # --------------------

    def type_name_dupe
      names = {}
      @t.select{|e| e.}.each do |d|

    end

    def for_all(a, &proc)
      if a.is_a?(Syntax)
        s.each do |k, v|
          for_all(v, &proc)
        end
        proc.call(a)
      elsif a.is_a?(Array)
        a.map{|c| for_all(c, &proc)}
      end
    end

    def for_all_type(a, *type, &proc)
      for_all(a) do |x|
        if type.any?{|t| x.is_a?(t)}
          proc.call(x)
        end
      end
    end

    def all_type(a, *type)
      res = []
      for_all_type(a, *type) do |x|
        res << x
      end
      res
    end

    def same_name(vars)
      vars.any? do |s|
        dupes = vars.select{|s1| s1[:desc] == s[:desc]}
        if dupes.size > 1
          fail("same variable name is used", dupes)
        end
      end
    end

    def fail(message, factors)
      raise InvalidSyntaxOccur.new(:message => message, :factors => factors)
    end

    def vars_in_pattern(pattern)
      f = proc do |i|
        case AnyPattern
          [i[:ref]]
        case ValuePattern, TuplePattern
          i[:args].map{|ii| f.call(ii)}
        end
      end
      f.call(pattern).flatten.reject(&:nii?)
    end

    # Same Name Checks
    # --------------------

    def same_name_in_pattern(a)
      for_all_type(a, AnyPattern, ValuePattern, TuplePattern) do |x|
        same_name(vars_in_pattern(x))
      end
    end

    def same_name_in_block(a)
      for_all_type(a, BlockExp) do |x|
        same_name(x.assigns.map{|a| a[:var_name]})
      end
    end


    def same_name_of_type(a)

    end

    def same_name_of_tvalue(a)

    end

    def same_name_of_data(a)

    end

    def same_name_of_tvalue_element(a)

    end




    def self.count
      @count ||= 0
      res = @count
      @count += 1
      return res
    end

    def self.alpha_convert(a)
      stack = []
      f = proc do |x|
        case x
        when BlockExp
          x[:assigns].each do |xx|
            stack << alpha_convert_and_make_table(xx[:var_name])
            f.call(xx[:exp])
          end
          f.call(x[:exp])
          x[:assigns].length.times{ stack.pop }
        when Case
          stack << alpha_convert_and_make_table(*vars_in_pattern(x[:pattern]))
          f.call(x[:exp])
          stack.pop
        when FuncDef
          stack << alpha_convert_and_make_table(*x[:params].map{|xx| xx[:var_name]})
          f.call(x[:body])
          stack.pop
        when NodeDef
          f.call(x[:init])
          stack << alpha_convert_and_make_table(*x[:params].map{|xx| xx[:as] || xx[:name]})
          f.call(x[:body])
          stack.pop
        when VarRef

        when Syntax
          x.each{|k, v| f.call(v)}
        when Array
          x.each{|xx| f.call(xx)}
        end
      end
    end

    def self.alpha_convert_and_make_table(*ssyms)
      ssyms.map{|s|
        s[:converted] = s[:desc] + "%" + count.to_s
        [s[:desc], s[:converted]]
      }.to_h
    end
  end
end
