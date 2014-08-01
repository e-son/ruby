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


ESON.registerTag("aaa","bbb")
ESON.resolveTag("aaa")

x = ESON.tags

#p = Strategies.new
#p::make_standard_strategy

#p Strategies.make_standard_strategy.call(struct_tag_strategy).call("aaa","bbb")
module Strategies

    @@ignore_tag_strategy = Proc.new {|id, data|
      data
    }

    @@struct_tag_strategy = Proc.new {|id, data|
      ESON::Tag.new(id, data)
    }

    @@error_tag_strategy = Proc.new {|id, data|
      raise "ERROR: Tag '#{id}' was not registered"
    }

    @@make_standard_tag_strategy = Proc.new {|default_strategy|
      default_strategy = default_strategy || @@error_tag_strategy
      Proc.new{|id, data|
        r = ESON.resolveTag(id)
        unless r.is_a?Proc
          default_strategy.call(id,data)
        else
          r.call(data)
        end
      }
    }

    def self.ignore_tag_strategy()
      @@ignore_tag_strategy
    end

    def self.struct_tag_strategy()
      @@struct_tag_strategy
    end

    def self.error_tag_strategy()
      @@error_tag_strategy
    end


    def self.make_standard_tag_strategy()
      @@make_standard_tag_strategy
    end
end


module ESON

  class Parser
    attr_accessor :tag_strategy

    def initialize(str)
      @list = []
      @pos = 0
      @tag_strategy = Strategies.make_standard_tag_strategy().call()
      tokenize(str)
    end

    def error(msg)
      raise "ERROR: #{msg} near #{@list[@pos - 1]}"
    end

    def tokenize(str)
      regex = /([\s\x20]+|:|,|\{|\}|\[|\]|true|false|null|\#([^\s\x20]*)|"(([^"\\]|\\.)*)"|([-0-9][-0-9eE.]*))/m

      list_with_spaces = str.split(regex)
      check_sum = 0
      for x in list_with_spaces
        check_sum += x.length
        #unless x =~ /^[\s ]+$/
        @list.push(x)
        #end
      end

      p list_with_spaces
      p "#{check_sum} #{str.length}"
      unless check_sum == str.length
        self.error("ERROR: Unexpected tokens")
      end

      def parse()
        res = self.parseVal()
        unless @pos == @list.length
          self.error("ERROR: Extra tokens")
        end
        return res
      end
    end

    def parseVal()
      v = @list[@pos]
      @pos += 1

      if v == '{'
        return self.parseObj()

      elsif v == '['
        return self.parseList()

      elsif v[0] == "\""
        return JSON.parse(v)

      elsif v[0] == 'n'
        return nil

      elsif v[0] == 't'
        return true

      elsif v[0] == 'f'
        return false

      elsif v[0] =~ /^[-0-9]$/
        return JSON.parse(v)

      else
        self.error("ERROR: Invalid token")
      end
    end

    def parseList()
      v = @list[@pos]

      if v == ']'
        @pos += 1
        return []
      end

      result = [self.parseVal()]

      while true
        v = @list[@pos]
        @pos += 1

        if v == ']'
          return result
        end

        self.error("ERROR: Expected ',' or ']'") unless v == ','

        x = self.parseVal()
        result.push(x)
      end
    end

    def parseObj()
      v = @list[@pos]
      @pos += 1
      result = {}

      if v == '}'
        return result
      end

      self.error("ERROR: Expected ',' or ']'") unless v == ','

      v = @list[@pos]
      @pos += 1
      self.error("ERROR: Expected string") unless v[0] == '\""'

      self.error ("ERROR: Expected ':'") unless @list[@pos] == ':'
      @pos += 1

      result[JSON.parse(v)] = self.parseVal()
    end
  end

  def self.parse(str, default_strategy = nil)
    p = ESON::Parser.new(str)
    p.tag_strategy = Strategies.make_standard_tag_strategy.call(default_strategy)
    p.parse()
  end
end

#p ESON.parse('[43]')

regex = /([-0-9][-0-9eE.]*)|\[|\]|\:/m

str = "[43]"
p str.scan(regex)


