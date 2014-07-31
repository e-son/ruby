require_relative '../eson'

# =======
# Parsing
# =======


# Tag parsing strategies
# ----------------------
#
# Tag parsing strategy is a function, which takes tag identifier and
# parsed data and returns object that is result of tag parsing.
#
# NOTE:
# Tag parsing handler is a function similar to strategy but it does not take
# identifier, since it should be bound to the identifier by outer mechanism.
# (Normally, by tag tree)


# Tag parsing strategy
# Ignores tags.

ignore_tag_strategy = Proc.new { |id, data|
  data
}

struct_tag_strategy = Proc.new {|id, data|
  ESON::Tag.new(id, data)
}

error_tag_strategy = Proc.new {|id, data|
  raise "ERROR: Tag '#{id}' was not registered"
}

make_standard_strategy = Proc.new {|default_strategy|
  default_strategy = default_strategy || error_tag_strategy
  Proc.new{|id, data|
    r = ESON.resolveTag(id)
    unless r.is_a?Proc
      default_strategy.call(id,data)
    else
      r.call(data)
    end
  }
}
ESON.registerTag("aaa","bbb")
ESON.resolveTag("aaa")
p make_standard_strategy.call(struct_tag_strategy).call("aaa","bbb")

module ESON
  class Parser
    def self.initialize(str)
      @list = []
      @pos = 0
      @tag_strategy = make_standard_tag_strategy(nil)
      self.tokenize(str)
    end

    def self.error(msg)
      self.error("ERROR: #{msg} near #{@list[@pos-1]}")
    end

    def self.tokenize(str)
      regex = 111 #TODO

      list_with_spaces = str.match(regex)
      check_sum = 0
      for x in list_with_spaces
        check_sum += x.length
        unless /^[\s ]+$/.test(x)
          @list.push(x)
        end
      end

      unless check_sum == str.length
        self.error("ERROR: Unexpected tokens")
      end

      def self.parse()
        res = self.parseVal()
        unless @pos == @list.length
          self.error("ERROR: Extra tokens")
        end
        return res
      end

      def self.parseVal()
        v = @list[pos]
        pos += 1

        if v == '{'
      end
    end
  end
end

x = 5
p x+=1