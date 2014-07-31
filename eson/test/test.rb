require_relative "../lib/eson"


ESON.generate({'aaa' => 11})
puts(ESON.parse("[432]"))
x = ESON::Tag.new(10,20)
puts(x.id)