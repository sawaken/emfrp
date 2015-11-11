module Emfrp
  module PreCheck
    def generate_tvalue_accessor(top)
      top[:types].each do |type|
        accessors = []
        type[:tvalues].each do |tvalue|
          accessors += tvalue[:params].map{|x| x[:name]}.reject(&:nil?)
        end
        accessors.uniq!
        accessors.each do |name|
          type[:tvalues].all? do |tvalue|
            matcheds = tvalue[:params].select{|x| x[:name] == name}
            if matcheds.size == 0
              err("Non-Comprehensive accessor definition exists", tvalue, name)
            elsif matcheds.size > 1
              err("Duplicate accessor name exists", tvalue, name)
            end
          end
        end
        accessors.each do |name|
          top[:funcs] << FuncDef.new(
            :name => name,
            :params => [
              ParamDef.new(
                :name => SSymbol.new(:desc => "x"),
                :type => nil
              )
            ],
            :type => nil,
            :body => MatchExp.new(
              :exp => VarRef.new(
                :name => SSymbol.new(:desc => "x")
              ),
              :cases => type[:tvalues].map{|tvalue|
                Case.new(
                  :pattern => ValuePattern.new(
                    :name => tvalue[:name],
                    :args => tvalue[:params].map{|param|
                      if param[:name] == name
                        AnyPattern.new(
                          :ref => SSymbol.new(:desc => "y")
                        )
                      else
                        AnyPattern.new(:ref => nil)
                      end
                    }
                  ),
                  :exp => VarRef.new(
                    :name => SSymbol.new(:desc => "y")
                  )
                )
              }
            )
          )
        end
      end
    end
  end
end
