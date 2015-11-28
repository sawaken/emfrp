require 'emfrp/convert/case_check'
require 'emfrp/convert/convert_into_monomorphic'
require 'emfrp/convert/find_used'
require 'emfrp/convert/calc_allocs'
require 'emfrp/convert/naming'

module Emfrp
  module Convert
    extend self

    def convert(top)
      case_check(top)
      convert_into_monomorphic(top)
      find_used(top)
      calc_allocs(top)
    end
  end
end
