module Emfrp
  class Table
    SyntaxError = Class.new(RuntimeError)

    def initialize(syntax)
      @type_table = make_type_table(syntax)
      @input_table = make_input_table(syntax)
      @output_table = make_output_table(syntax)
      @func_table = make_func_table(syntax)
      @method_table = make_method_table(syntax)
    end

    def make_input_table(syntax)
      xs = syntax.select{|s| InputDef === s}.group_by{|s| s[:name]}
      res = {}
      xs.each do |k, v|
        if v.size != 0
          raise SyntaxError.new("input name dupe", v)
        end
        res[k[:desc]] = v[0]
      end
      return res
    end

    def make_output_table(syntax)

    end
  end
end
