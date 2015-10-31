module Emfrp
  class Syntax < Hash
    def initialize(hash, hash2 = {})
      self[:class] = self.class
      self.merge!(hash)
      self.merge!(hash2)
      self[:class] = self.class
    end

    def [](key)
      if self.has_key?(key)
        self.fetch(key)
      else
        pp self
        raise "unexist key #{key}"
      end
    end
  end

  Types = [
    :SSymbol,
    :InputDef, :OutputDef, :InitializeDef, :DataDef, :FuncDef, :MethodDef, :NodeDef, :TypeDef, :CTypeDef, :InfixDef,
    :InitializeTargetDef,
    :ParamDef, :Type, :TupleType, :TValue, :TValueParam, :NodeConst, :InitDef, :LazyDef, :CExp,
    :NodeParam, :NodeLast, :NodeConstLift, :NodeConstClockEvery, :NodeConstInputQueue,
    :IfExp, :MapExp, :MatchExp, :Case,
    :AnyPattern, :ValuePattern, :TuplePattern, :IntPattern,
    :UnaryOperatorExp, :OperatorSeq, :BinaryOperatorExp,
    :MethodCall, :FuncCall, :BlockExp, :Assign, :ValueConst, :ArrayConst, :GFConst, :SkipExp, :VarRef,
    :LiteralTuple, :LiteralArray, :LiteralString,
    :LiteralIntegral, :LiteralFloating
  ]
  Types.each do |t|
    const_set(t, Class.new(Syntax))
  end
end
