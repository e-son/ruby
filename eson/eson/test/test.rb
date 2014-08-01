require_relative "../lib/eson"


#puts(ESON.generate(['aaa',"aaaaa",32]))
#puts(ESON.generate({'aaa' => 11}))
#puts(ESON.parse.rb("[432]"))
x = ESON::Tag.new(10,20)
puts(x.id)

ESON.registerTag("aaa",{})
ESON.registerTag("aaa/aaa",{})
p ESON.resolveTag("aaa")
ESON.deleteTag("aaa")
p ESON.resolveTag("aaa")


f = Proc.new do |dist, *args|
  p "TEST"
end

ESON.registerTag("aaa",{})
ESON.registerTag("aaa/aaa",{})
ESON.registerTag("aaa/aaa/aaa",f)

ESON.resolveTag("aaa/aaa/aaa").call(f)


t = ESON::Tag.new("foo", 47)
p ESON.generate(t)

p ESON.generate([t])
p ESON.generate({"aaa" => t})


p JSON.parse("[\"aaa\"]")


ESON.registerTag("tag47",Proc.new{|arg| "TEST"})

p ESON.parse('{"medved" : [#tag47 221, "sssss"]}')
p ESON.struct_parse('{"medved" : [#ssss 221, "sssss"]}')
p ESON.pure_parse('{"medved" : [#ssss 221, "sssss"]}')