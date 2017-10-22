require "settingslogic"
require "pry"

class Settings < Settingslogic
  source "#{File.dirname(__FILE__)}/settings.yml"

  class << self
    def qqqq
      method_missing(:aaaaa)
    end

    def access
      # 先に Settings.test とかやってインスタンス変数を生成してから使う
      @instance
    end

    private
    # def method_missing(name, *args, &block)
    #   binding.pry
    # end

    def tuoiuero
      p 87655
    end
  end

  private
  # def method_missing(name, *args, &block)
  #   p 9999999
  # end

  #binding.pry
end

class Test
  class << self
    def test=(test)
      @test = test
    end

    def test
      @test
    end
  end
end

a = Test.new

a.class.class_eval <<-EndEval
  def tttt
    p "aiueo"
  end

  class << self
    def qqqq
      p 9876
    end
  end
EndEval

a.class.instance_eval <<-EndEval
  def iiii
    p "testo-"
  end

  class << self
    def zzzz
      p 66666
    end
  end
EndEval

a.instance_eval <<-TesEval
  def ooooo
    p "ooooooo"
  end

  class << self
    def uuuuu
      p 111111
    end
  end
TesEval

binding.pry

# a.tttt => "aiueo"
# Test.qqqq => 9876
# a.uuuuu => 111111
# a.ooooo => "ooooooo"

# a.methods => [:ooooo, :uuuuu, :tttt]
# Test.methods => [qqqq, :iiii, :zzzz]
