module Emfrp
  class CompileError < RuntimeError
    attr_reader :message, :factors

    def initialize(message, *factors)
      @message, @factors = message, factors
    end

    def tag_comp(a, b)
      [a[:line_number], a[:column_number]] <=> [b[:line_number], b[:column_number]]
    end

    def collect_factor_tags(factor)
      case factor
      when Syntax
        if factor.has_key?(:start_pos)
          collect_factor_tags(factor.values) + [[factor[:start_pos], factor[:end_pos]]]
        else
          collect_factor_tags(factor.values)
        end
      when Array
        factor.flat_map{|x| collect_factor_tags(x)}
      else
        []
      end
    end

    def find_factor_file_name(factor)
      case factor
      when Syntax
        if factor.has_key?(:start_pos)
          return factor[:start_pos][:document_name]
        else
          return find_factor_file_name(factor.values)
        end
      when Array
        factor.each do |x|
          if res = find_factor_file_name(x)
            return res
          end
        end
      end
      return nil
    end

    def factor_name(factor)
      klass = factor.class.name.split("::").last
      if factor.is_a?(Syntax)
        name = factor.has_key?(:name) ? "`#{factor[:name][:desc]}`" : ""
      else
        name = factor.inspect
      end
      klass + " " + name
    end

    def print_lexical_factor(factor, factor_num, output_io, src_strs, file_names)
      src_lines = nil
      factor_file_name = find_factor_file_name(factor)
      src_strs.zip(file_names).each do |src_str, file_name|
        if file_name == factor_file_name
          src_lines = src_str.each_line.to_a
        end
      end
      tags = collect_factor_tags(factor)
      spos = tags.map{|x| x[0]}.min{|a, b| tag_comp(a, b)}
      epos = tags.map{|x| x[1]}.max{|a, b| tag_comp(a, b)}
      line_nums = (spos[:line_number]..epos[:line_number]).to_a
      if line_nums.size == 1
        output_io << "#{factor_file_name}:#{line_nums[0]}:\n"
        output_io << "> " + src_lines[line_nums[0] - 1]
        output_io << "  " + " " * (spos[:column_number] - 1)
        output_io << "\e[32m" + "^" * (epos[:column_number] - spos[:column_number] + 1) + "\e[m" + "\n"
      else
        output_io << "#{factor_file_name}:#{line_nums.first}-#{line_nums.last}:\n"
        line_nums.each do |line_num|
          output_io << "> " + src_lines[line_num - 1]
        end
      end
    end

    def print_error(output_io, src_strs, file_names)
      output_io << "#{@message}:\n"
      @factors.each_with_index do |factor, i|
        output_io << "FACTOR-#{i}: #{factor_name(factor)}\n"
        if find_factor_file_name(factor)
          print_lexical_factor(factor, i, output_io, src_strs, file_names)
        end
      end
    end
  end
end
