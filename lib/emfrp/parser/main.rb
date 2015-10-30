require 'parser_combinator/string_parser'

require 'emfrp/syntax'
require 'emfrp/parser/toplevel'
require 'emfrp/parser/expression'
require 'emfrp/parser/misc'

module Emfrp
  class Parser < ParserCombinator::StringParser
    def self.parse(src_str, filename)
      case res = whole_src.parse_from_string(convert_case_group(src_str), filename)
      when Fail
        ln = res.status.rest[0].tag[:line_number]
        col = res.status.rest[0].tag[:column_number]
        line = src_str.each_line.to_a[ln - 1]
        puts "#{filename}:#{ln}: Syntax error, in `#{res.status.message[:place]}`: required #{res.status.message[:required]}"
        puts "#{line}"
        puts "#{" " * (col - 1)}^ "
      else
        res
      end
    end

    def self.convert_case_group(src_str)
      raise "TAB Occurs!!!" if src_str.chars.include?("\t")
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

    def self.infix_rearrage(s)

    end

    def err(place, required)
      self.onfail(:place => place, :required => required)
    end
  end
end
