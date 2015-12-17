require "pp"

require "emfrp/version"
require 'emfrp/compile_error'
require 'emfrp/syntax'
require "emfrp/pre_convert/pre_convert"
require "emfrp/parser/parser"
require 'emfrp/typing/typing'
require 'emfrp/interpreter/interpreter'
require 'emfrp/compile/c/codegen'

module Emfrp
  IncludeDirs = [Dir.pwd + "/", File.dirname(__FILE__) + "/../mfrp_include/"]
end
