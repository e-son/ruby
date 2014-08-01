require 'time'

# ==============
# Core namespace
# ==============


# Set of built-in tag handlers
module ESON
  self.registerTag('core',{});
  # Datetime should be ISO format string, but it can be anything Date accepts
  self.registerTag('datetime', Proc.new{|str| Time.new(str)})
end

class Time
  # Tell Date how to stringify
  # It has built-in tag and uses ISO format
  def to_eson()
    ESON::Tag.new('core/datetime', self.iso8601)
  end
end