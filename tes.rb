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

class NotAuthorizedError < StandardError
  attr_reader :controller, :query, :loyalty

  def initialize(options={})
    if options.is_a? String
      message = options
    else
      @controller = options[:controller]
      @query      = options[:query]
      @loyalty    = options[:loyalty]

      message = options.fetch(:message) { "not allowed to #{query} of #{controller} by #{loyalty.inspect}" }
    end

    super(message)
  end
end

# a = TestClass.new
# a.aaa
#
# p TestModule::TTT
# p __FILE__
# p File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

a = NotAuthorizedError.new(controller: "posts_controller", query: "update?", loyalty: TestClass.new.inspect)

binding.pry
