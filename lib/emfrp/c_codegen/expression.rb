module Emfrp
  module CExpression < Syntax
    ExpTypes = [
      :If, :Let, :Ret, :Call, :Var, :Prim
    ]
    ExpTypes.each do |t|
      const_set(t, Class.new(CExpression))
    end
  end
end
