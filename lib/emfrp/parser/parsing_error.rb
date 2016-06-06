require 'colorize'

module Emfrp
  class Parser
    class ParsingError < StandardError
      def initialize(src_str, file_name, status)
        @src_str = src_str
        @file_name = file_name
        @status = status
      end

      def code
        @status.message[:code] || :noname
      end

      def line_number
        if @status.rest.length > 0
          @status.rest[0].tag[:line_number]
        else
          @src_str.each_line.count
        end
      end

      def column_number
        if @status.rest.length > 0
          @status.rest[0].tag[:column_number]
        else
          @src_str.each_line.last.length
        end
      end

      def line
        @src_str.each_line.to_a[line_number - 1]
      end

      def print_error(output_io)
        output_io << "#{@file_name}:#{line_number}: "
        output_io << "SyntaxError, in `#{@status.message[:place]}`: "
        output_io << "#{@status.message[:required]} is expected"
        if @status.rest.length == 0
          output_io << ", but parser reached end-of-file\n"
        else
          output_io << "\n#{line.chomp}\n"
          output_io << "#{" " * (column_number - 1)}#{"^".colorize(:green)}\n"
        end
      end
    end
  end
end
