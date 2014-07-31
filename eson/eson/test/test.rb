require_relative "../lib/eson"


#puts(ESON.generate(['aaa',"aaaaa",32]))
#puts(ESON.generate({'aaa' => 11}))
#puts(ESON.parse("[432]"))
x = ESON::Tag.new(10,20)
puts(x.id)

ESON.registerTag("aaa",{})
ESON.registerTag("aaa/aaa",{})
p ESON.resolveTag("aaa")
ESON.deleteTag("aaa")
p ESON.resolveTag("aaa")



t = ESON::Tag.new("aaa/aaa",47)

p ESON.generate(t)