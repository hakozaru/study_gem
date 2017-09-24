require 'rubygems'
require 'banken' # gem install banken やっておく
require 'pry'
require "./module"

class TestClass
  include TestModule
  include Banken
  #extend Banken

  class << self
    def bbb
      p "9999"
    end
  end

  def aaa
    mod
  end
end


a = TestClass.new
a.aaa

p TestModule::TTT
p __FILE__
p File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
#binding.pry
