require 'parser_combinator'

module Emfrp
  class OpParser < ParserCombinator
    def self.make_op_parser(priority_list)
      priority_list.reverse.inject(item.map(&:item)) do |contp, x|
        op = sat{|i| i.item.is_a?(SSymbol) && i.item[:desc] == x[:sym]}
        if x[:dir] == "left"
          opp = x[:op].map do |op|
            proc{|l, r| BinaryOperatorExp.new(:tag => l[:tag], :op => op, :left => l, :right => r)}
          end
          binopl_fail(contp, opp)
        elsif x[:dir] == "right"
          sp = contp >> proc{|l|
            x[:op] >> proc{|op|
              sp >> proc{|r|
                ok(BinaryOperatorExp.new(:tag => l[:tag], :op => op, :left => l, :right => r))
              }}} | contp
        else
          raise "invalid direction"
        end
      end
    end
  end
end
