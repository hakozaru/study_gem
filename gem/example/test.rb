require "pry"
require "settingslogic"

class Hako < Settingslogic
  source "#{File.dirname(__FILE__)}/setting.yml"
end

Hako.test
  # Hako.test
  # => {"text1"=>"abcd", "text2"=>"xyz"}
