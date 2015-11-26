require 'colorize'

module Emfrp
  module Typing
    class TypeMatchingError < CompileError
      def initialize(real_utype, expected_utype, place, *factors)
        @real_utype = real_utype
        @expected_utype = expected_utype
        @place = place
        @factors = factors
      end

      def print_error(output_io, file_loader)
        output_io << "[Type Matching Error]".colorize(:red) + ": For #{@place}:\n"
        output_io << "Expected: " + "#{@expected_utype.to_uniq_str}".colorize(:green) + "\n"
        output_io << "Real: " + "#{@real_utype.to_uniq_str}".colorize(:green) + "\n"
        @factors.each do |factor|
          print_lexical_factor(factor, output_io, file_loader)
        end
      end
    end

    class TypeDetermineError < CompileError
      def initialize(undetermined_utype, factor)
        @utype = undetermined_utype
        @factor = factor
      end

      def print_error(output_io, file_loader)
        output_io << "[Undetermined Type Error]".colorize(:red) + ":\n"
        output_io << "Undetermined: " + "#{@utype.to_uniq_str}".colorize(:green) + "\n"
        print_lexical_factor(@factor, output_io, file_loader)
      end
    end
  end
end
