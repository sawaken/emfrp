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

    def traverse_all_syntax(target=self, &block)
      case target
      when Syntax
        block.call(target)
        traverse_all_syntax(target.values, &block)
      when Array
        target.each{|e| traverse_all_syntax(e, &block)}
      end
    end
  end

  class Link
    def initialize(syntax)
      @link = syntax
    end

    def get
      @link
    end

    def hash
      @link.object_id
    end

    def eql?(other)
      self.hash == other.hash
    end

    def inspect
      @link ? "Link" : "NullLink"
    end

    def to_s
      inspect
    end
  end

  class SSymbol < Syntax
    def ==(other)
      self[:desc] == other[:desc]
    end

    def hash
      self[:desc].hash
    end

    def eql?(other)
      self.hash == other.hash
    end

    def pretty_print(q)
      q.text '"' + self[:desc] + '"'
    end
  end

  class Top < Syntax
    def initialize(hash={})
      self[:inputs] = []
      self[:outputs] = []
      self[:inits] = []
      self[:datas] = []
      self[:funcs] = []
      self[:nodes] = []
      self[:types] = []
      self[:ctypes] = []
      self[:infixes] = []
      merge!(hash)
    end
  end

  Types = [
    :InputDef, :OutputDef, :InitializeDef, :DataDef, :FuncDef, :MethodDef, :NodeDef, :TypeDef, :CTypeDef, :InfixDef,
    :InitializeTargetDef,
    :ParamDef, :Type, :TypeVar, :TValue, :TValueParam, :NodeConst, :InitDef, :LazyDef, :CExp,
    :NodeParam, :NodeRef, :NodeConstLift, :NodeConstClockEvery, :NodeConstInputQueue,

    # Expression
    :IfExp, :MatchExp, :Case,
    :AnyPattern, :ValuePattern, :TuplePattern, :IntegralPattern,
    :UnaryOperatorExp, :OperatorSeq, :BinaryOperatorExp,
    :MethodCall, :FuncCall, :BlockExp, :Assign, :ValueConst, :GFConst, :SkipExp, :VarRef,
    :LiteralTuple, :LiteralArray, :LiteralString, :LiteralChar,
    :LiteralIntegral, :LiteralFloating
  ]
  Types.each do |t|
    const_set(t, Class.new(Syntax))
  end
end
