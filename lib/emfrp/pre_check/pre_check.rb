require 'emfrp/pre_check/associate_constructor'
require 'emfrp/pre_check/associate_func_and_data'
require 'emfrp/pre_check/associate_var'
require 'emfrp/pre_check/check_node'
require 'emfrp/pre_check/check_recursive_call'
require 'emfrp/pre_check/check_type'
require 'emfrp/pre_check/generate_tvalue_accessor'
require 'emfrp/pre_check/check_skip_position'
require 'emfrp/compile_error'

module Emfrp
  module PreCheck
    extend self

    PreCheckError = Class.new(CompileError)

    def check(top)
      generate_tvalue_accessor(top)
      associate_var(top)
      associate_func_and_data(top)
      associate_constructor(top)
      check_node(top)
      check_type(top)
      check_recursive_call(top)
      check_skip_position(top)
    end

    def err(msg, *facts)
      raise PreCheckError.new(msg, *facts)
    end
  end
end
