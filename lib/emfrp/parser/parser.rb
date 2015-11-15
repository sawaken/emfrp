require 'parser_combinator/string_parser'

require 'emfrp/syntax'
require 'emfrp/parser/toplevel'
require 'emfrp/parser/expression'
require 'emfrp/parser/misc'
require 'emfrp/parser/operator'

module Emfrp
  class Parser < ParserCombinator::StringParser
    ParsingError = Class.new(RuntimeError)

    def self.parse_all(inputs)
      inputs.inject([]) do |acc, input|
        acc + Parser.parse(input[:src], input[:filename])
      end
    end

    def self.parse(src_str, filename)
      puts convert_case_group(src_str)
      case res = whole_src.parse_from_string(convert_case_group(src_str), filename)
      when Fail
        if res.status.rest[0]
          ln = res.status.rest[0].tag[:line_number]
          col = res.status.rest[0].tag[:column_number]
        else
          ln = src_str.each_line.count
          col = src_str.each_line.to_a.last.size
        end
        line = src_str.each_line.to_a[ln - 1]
        msg = ""
        msg << "#{filename}:#{ln}: Syntax error, in `#{res.status.message[:place]}`: "
        msg << "required #{res.status.message[:required]}\n"
        msg << "#{line}"
        msg << "#{" " * (col - 1)}^ \n"
        raise ParsingError.new(msg)
      else
        infix_rearrange(res.parsed)
      end
    end

    def self.convert_case_group(src_str)
      raise ParsingError.new("TAB is not allowed to use in sources.") if src_str.chars.include?("\t")
      lines = src_str.each_line.to_a.map(&:chomp)
      len = lines.length
      len.times do |ln|
        if lines[ln].strip.chars.last == ":"
          width = lines[ln].chars.take_while{|c| c == "\s"}.size
          ((ln+1)..(len-1)).each do |ln2|
            width2 = lines[ln2].chars.take_while{|c| c == "\s"}.size
            if lines[ln2].strip == ""
              next
            elsif width2 <= width
              lines[ln2 - 1] << " :endcase"
              break
            elsif ln2 == len - 1
              lines[ln2] << " :endcase"
              break
            end
          end
        end
      end
      lines.map{|l| l + "\n"}.join
    end

    def self.infix_rearrange(top)
      priority_listl = [[], [], [], [], [], [], [], [], [], []]
      priority_listr = [[], [], [], [], [], [], [], [], [], []]
      priority_listn = [[], [], [], [], [], [], [], [], [], []]
      defined_op = {}
      top[:infixes].reverse.each do |id|
        if defined_op[id[:op][:desc]]
          next
        else
          defined_op[id[:op][:desc]] = true
        end
        if id[:priority] == nil || ("0" <= id[:priority][:desc] && id[:priority][:desc] <= "9")
          priority = id[:priority] == nil ? 9 : id[:priority][:desc].to_i
          opp = sat{|i| i.is_a?(SSymbol) && i[:desc] == id[:op][:desc]}.map(&:item)
          if id[:type][:desc] == "infix"
            priority_listn[priority] << opp
          elsif id[:type][:desc] == "infixl"
            priority_listl[priority] << opp
          elsif id[:type][:desc] == "infixr"
            priority_listr[priority] << opp
          else
            raise "invalid infix type"
          end
        else
          raise "invalid prirority"
        end
      end
      priority_list = [{:op => sat{|i| i.is_a?(SSymbol)}.map(&:item), :dir => "left"}]
      10.times do |i|
        if priority_listl[i].length > 0
          priority_list << {:op => priority_listl[i].inject(&:|), :dir => "left"}
        end
        if priority_listr[i].length > 0
          priority_list << {:op => priority_listr[i].inject(&:|), :dir => "right"}
        end
        if priority_listn[i].length > 0
          priority_list << {:op => priority_listn[i].inject(&:|), :dir => "left"}
        end
      end
      return infix_convert(top, OpParser.make_op_parser(priority_list))
    end

    def self.infix_convert(s, parser)
      if s.is_a?(Syntax)
        new_s = s.class.new(s.map{|k, v| [k, infix_convert(v, parser)]}.to_h)
        if s.is_a?(OperatorSeq)
          items = Items.new(new_s[:seq].map{|c| Item.new(c, nil)})
          res = parser.parse(items)
          if res.is_a?(Fail)
            raise "operator parsing fail!!"
          end
          res.parsed
        else
          new_s
        end
      elsif s.is_a?(Array)
        s.map{|c| infix_convert(c, parser)}
      else
        s
      end
    end

    def err(place, required)
      self.onfail(:place => place, :required => required)
    end

    def to_nil
      self.map{|x| x[0]}
    end
  end
end
