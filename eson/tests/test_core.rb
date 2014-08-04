require_relative "./helpers/JSONs"
require "test/unit"
require "json"
require_relative "../lib/eson"

class Test_JSON_core < Test::Unit::TestCase
  def setup
    @stable_data = ['[',
    '#core/datetime "1500-01-20T04:47:47", ',
    '#core/datetime "1600-02-19T08:47:47.123456", ',
    '#core/datetime "1700-03-18T12:47:47+08:30", ',
    '#core/datetime "1800-04-17T16:47:47.123456-01:30", ',
    '#core/datetime "1900-05-16T20:47:47-00:30"',
    ']'].join('')
    @unstable_data = ['[',
    '#core/datetime "1500-01-20T04:47:47Z", ',
    '#core/datetime "1600-02-19T08:47:47.123+00:30", ',
    '#core/datetime "1700-03-18T12:47:47.0Z", ',
    '#core/datetime "1800-04-17T16:47:47.123456789-00:30"',
    ']'].join('')
  end

  # def teardown
  # end

  def test_stable_data
    #p @stable_data
    p @stable_data
    obj1 = ESON.parse(@stable_data);
    str1 = ESON.generate(obj1)
    obj2 = ESON.parse(str1)


    assert_equal(@stable_data, str1, " #core/datetime should be encoded and decoded properly")
    assert_equal(obj1, obj2, " #core/datetime should be encoded and decoded properly")
  end
begin
  def test_unstable_data
    obj1 = eson.parse(@unstable_data)
    str1 = eson.generate(obj1)
    obj2 = eson.parse(str1)
    str2 = eson.generate(obj2)

    assert_equal(str1, str2, " #core/datetime should be encoded and decoded properly")
    assert_equal(obj1, obj2, " #core/datetime should be encoded and decoded properly")
  end
end

end