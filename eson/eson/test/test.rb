require_relative "../lib/eson"


puts(ESON.generate(['aaa',"aaaaa",32]))
puts(ESON.generate({'aaa' => 11}))
puts(ESON.parse("[432]"))
x = ESON::Tag.new(10,20)
puts(x.id)

