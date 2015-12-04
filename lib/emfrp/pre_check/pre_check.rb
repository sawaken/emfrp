require 'emfrp/pre_check/associate_and_flatten'
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
      AssociateAndFlatten.convert(top)
      associate_var(top)
      associate_func_and_data(top)
      associate_constructor(top)

      # RuleCheck

      check_node(top)
      check_type(top)
      check_recursive_call(top)
      check_skip_position(top)
    end

    def additional_check(top, definition)
      AssociateAndFlatten.additional_convert(top, definition)

      if definition.is_a?(DataDef)
        definition[:binds] = [definition[:name]]
        top[:datas] << definition
      end
      associate_var(definition, top[:datas])

      if definition.is_a?(FuncDef) || definition.is_a?(PrimFuncDef) || definition.is_a?(DataDef)
        definition[:depends] = []
      end
    end

    def err(msg, *facts)
      raise PreCheckError.new(msg, *facts)
    end
  end
end
