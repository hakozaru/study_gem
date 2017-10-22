require "settingslogic"
require "pry"

class Settings < Settingslogic
  source "#{File.dirname(__FILE__)}/settings.yml"

  binding.pry
end
