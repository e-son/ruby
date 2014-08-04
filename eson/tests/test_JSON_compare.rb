require_relative "./helpers/JSONs"
require "test/unit"
require "json"
require_relative "../lib/eson"

class Test_JSON_compare < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_parse
    Generate.new().each { |name, data|
      s = ESON.JSONGenerateWrapper(data)
      assert_equal(ESON.JSONParseWrapper(s), ESON.parse(s), "should be consistent with JSON.parse on JSON named #{name}")
    }
  end

  def test_generate
    Generate.new().each { |name, data|
      s = ESON.JSONGenerateWrapper(data)
      assert_equal(s, ESON.generate(data), "should be consistent with JSON.stringify on JSON named #{name}")
    }
  end


end