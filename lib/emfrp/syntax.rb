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

    def deep_copy(x=self)
      case x
      when Syntax
        x.class.new(x.map{|k, v| [k, deep_copy(v)]}.to_h)
      when Array
        x.map{|x| deep_copy(x)}
      else
        x
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
      if @link.has_key?(:name)
        "Link(#{@link[:name][:desc]})"
      else
        "Link(#{@link.class})"
      end
    end

    def to_s
      inspect
    end
  end

  class SSymbol < Syntax
    def ==(other)
      if other.is_a?(SSymbol)
        self[:desc] == other[:desc]
      else
        super
      end
    end

    def hash
      self[:desc].hash
    end

    def eql?(other)
      if other.is_a?(SSymbol)
        self.hash == other.hash
      else
        super
      end
    end

    def pretty_print(q)
      q.text '"' + self[:desc] + '"'
    end
  end

  class Top < Syntax
    ATTRS = [
      :inputs,
      :outputs,
      :inits,
      :datas,
      :funcs,
      :nodes,
      :types,
      :ctypes,
      :infixes,
    ]
    def initialize(*tops)
      ATTRS.each do |a|
        self[a] = tops.map{|h| h[a]}.flatten
      end
    end
  end

  Types = [
    :InputDef, :OutputDef, :InitializeDef, :DataDef, :FuncDef, :MethodDef, :NodeDef, :TypeDef, :CTypeDef, :InfixDef,
    :InitializeTargetDef,
    :ParamDef, :Type, :TypeVar, :TValue, :TValueParam, :NodeConst, :InitDef, :LazyDef, :CExp,
    :NodeParam, :NodeRef, :NodeConstLift, :NodeConstClockEvery, :NodeConstInputQueue,

    # Expression
    :MatchExp, :Case,
    :AnyPattern, :ValuePattern, :TuplePattern, :IntegralPattern,
    :UnaryOperatorExp, :OperatorSeq, :BinaryOperatorExp,
    :MethodCall, :FuncCall, :Assign, :ValueConst, :GFConst, :SkipExp, :VarRef,
    :LiteralTuple, :LiteralArray, :LiteralString, :LiteralChar, :ParenthExp,
    :LiteralIntegral, :LiteralFloating
  ]
  Types.each do |t|
    const_set(t, Class.new(Syntax))
  end
end
