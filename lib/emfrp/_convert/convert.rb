require 'emfrp/convert/convert_into_monomorphic'
require 'emfrp/convert/find_used'
require 'emfrp/convert/calc_allocs'
require 'emfrp/convert/node_sort'

module Emfrp
  module Convert
    extend self

    def convert(top)
      convert_into_monomorphic(top)
      find_used(top)
      calc_allocs(top)
      node_sort(top)
    end
  end
end
