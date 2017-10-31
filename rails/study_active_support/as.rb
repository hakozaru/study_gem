require "pry"
require "active_support"
require "active_support/core_ext"

#p $LOAD_PATH

class Test
  mattr_accessor :hakozaru, instance_accessor: true
  mattr_accessor :hoge
  mattr_accessor :huga, instance_accessor: false
end

binding.pry
