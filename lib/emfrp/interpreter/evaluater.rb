module Emfrp
  class Interpreter
    module Evaluater
      extend self

      def eval_to_str(top, exp)
        v = eval_exp(top, exp)
        return "#{value_to_s(v)} : #{exp[:typing].to_uniq_str}"
      end

      def assert_equals(top, exp1, exp2)
        v1 = eval_exp(top, exp1)
        v2 = eval_exp(top, exp2)
        return v1 == v2
      end

      def eval_exp(exp, env={})
        case exp
        when FuncCall
          case f = exp[:func].get
          when PrimFuncDef
            if ruby_exp = f[:foreigns].find{|x| x[:language][:desc] == "ruby"}
              proc_str = "proc{|#{f[:params].map{|x| x[:name][:desc]}.join(",")}| #{ruby_exp[:desc]}}"
              eval(proc_str).call(*exp[:args].map{|e| eval_exp(e, env)})
            else
              raise "Primitive Function `#{f[:name][:desc]}` is not defined for ruby"
            end
          when FuncDef
            f[:params].map{|param| [param[:name], Link.new(f)]}.zip(exp[:args]).each do |key, arg|
              env[key] = eval_exp(arg, env)
            end
            eval_exp(f[:exp], env)
          end
        when ValueConst
          [exp[:name][:desc].to_sym] + exp[:args].map{|e| eval_exp(e, env)}
        when LiteralIntegral
          exp[:entity][:desc].to_i
        when LiteralChar
          exp[:entity].ord
        when LiteralFloating
          exp[:entity][:desc].to_f
        when VarRef
          key = [exp[:name], exp[:binder]]
          if exp[:binder].get.is_a?(DataDef) && !env[key]
            env[key] = eval_exp(exp[:binder].get[:exp], env)
          end
          env[key]
        when MatchExp
          left_val = eval_exp(exp[:exp], env)
          exp[:cases].each do |c|
            if match_result = pattern_match(c, left_val)
              return eval_exp(c[:exp], env.merge(match_result))
            end
          end
          raise "pattern match fail"
        else
          raise "Unexpected expression type #{exp.class} (bug)"
        end
      end

      def pattern_match(c, v, pattern=c[:pattern], vars={})
        if pattern[:ref]
          key = [pattern[:ref], Link.new(c)]
          vars[key] = v
        end
        case pattern
        when ValuePattern
          if v.is_a?(Array) && pattern[:name][:desc].to_sym == v[0]
            res = v.drop(1).zip(pattern[:args]).all? do |ch_v, ch_p|
              pattern_match(c, ch_v, ch_p, vars)
            end
            return vars if res
          end
        when IntegralPattern
          if v.is_a?(Integer) && pattern[:val][:entity][:desc].to_i == v
            return vars
          end
        when AnyPattern
          return vars
        end
        return nil
      end

      def value_to_s(val)
        if val.is_a?(Array) && val.first.is_a?(Symbol)
          "#{val.first}" + (val.size > 1 ? "(#{val.drop(1).map{|x| value_to_s(x)}.join(", ")})" : "")
        else
          val.to_s
        end
      end
    end
  end
end
