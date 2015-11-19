module Emfrp
  class Interpreter
    def initialize
      @env = {}
    end

    def eval(exp)
      case exp
      when FuncCall
        args = exp[:args].map{|x| eval(x)}
        func = exp[:func].get
        case func[:body]
        when SSymbol
          raise "cannot eval foreign function"
        when CExp
          param_names = func[:params].map{|x| x[:name][:desc]}
          proc = eval "proc{|#{param_names.join(",")}| #{func[:body]}}"
          proc.call(*args)
        else
          
        end
      when

    end
  end
end
