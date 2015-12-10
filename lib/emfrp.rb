require "pp"

require "emfrp/version"
require "emfrp/parser/parser"
require 'emfrp/typing/typing'
require 'emfrp/codegen/c/codegen'
require 'emfrp/compile_error'

#require 'emfrp/convert/convert'
require 'emfrp/interpreter/interpreter'

module Emfrp
  IncludeDirs = [Dir.pwd + "/", File.dirname(__FILE__) + "/../mfrp_include/"]
end
