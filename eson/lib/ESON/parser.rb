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



module Strategies

    # Tag parsing strategy
    # Ignores tags.
    @@ignore_tag_strategy = Proc.new {|id, data|
      data
    }


    # Tag parsing strategy
    # Parses tags to ESON.Tag objects.
    @@struct_tag_strategy = Proc.new {|id, data|
      ESON::Tag.new(id, data)
    }


    # Tag parsing strategy
    # Raises error - used as default in make_standard_tag_strategy.
    @@error_tag_strategy = Proc.new {|id, data|
      raise "ERROR: Tag '#{id}' was not registered"
    }


    # Strategy for tag parsing.
    # Tries to use registered handler and use given default_strategy otherwise
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

  # ESON parsing overview
  # ---------------------
  #
  # Firstly, string is split into tokens like strings, numbers, tags
  # or separators that are atomic for parser. There is an virtual pointer to the
  # tokens list. Functions like parseVal, parseList or parseObj are supposed to
  # parse ESON object starting at the current pointer position, move the pointer
  # behind the object's end and return parsed value or throw error if tokens
  # are not correct. This behavior enables easy recursive use.


  # so we can parse single values like true, false, strings, numbers not contained in arrays, nor objects
  def self.JSONParseWrapper(str)
    str = '[' + str + ']'
    JSON.parse(str)[0]
  end

  # Class which stores data during parsing
  # Relieves argument passing
  class Parser
    attr_accessor :tag_strategy

    # Initiates Parser
    def initialize(str)
      @list = []
      @pos = 0
      @tag_strategy = Strategies.make_standard_tag_strategy().call()
      tokenize(str)
    end

    def loadTokens(tokenList)
      @list = tokenList
    end

    # Function used to raise error
    # (including details may be repetitive)
    def error(msg)
      raise "ERROR: #{msg} near #{@list[@pos - 1]}"
    end


    # Check that the string is composed of tokens and split it into them
    def tokenize(str)

      #TODO REGEX TO RECOGNIZE STRING MAY NOT BE OK
      # Regex to tokenize string
      regex =  /[\s\x20]+|:|,|\{|\}|\[|\]|true|false|null|[-0-9][-0-9eE.]*|#[^\s\x20]*|"\w*"/m


      # Get all tokens, sum the lengths to check validity
      # and throw away the spaces
      list_with_spaces = str.scan(regex)

      check_sum = 0
      for x in list_with_spaces
        check_sum += x.length
        unless x =~ /^[\s ]+$/
          @list.push(x)
        end
      end

      # There shouldn't be anything else than tokens and spaces
      unless check_sum == str.length
        self.error("ERROR: Unexpected tokens")
      end

      # Starts parsing
      def parse()

        # ESON is expected to be any value
        res = self.parseVal()

        # Everything should be parsed
        self.error("ERROR: Extra tokens") unless @pos == @list.length
        return res
      end
    end


    def parseVal()

      # Get next token
      v = @list[@pos]
      @pos += 1

      # Is it an object?
      if v == '{'
        return self.parseObj()

      # Is it a list?
      elsif v == '['
        return self.parseList()

      # Is it a string?
      elsif v[0] == "\""
        return ESON.JSONParseWrapper(v)  # use JSON for strings

      # Is it a tagged value?
      elsif v[0] == '#'
        tag = v[1..v.length - 1]  # get tagged string
        val = self.parseVal()  # again, value follows
        return @tag_strategy.call(tag, val)

      # Is it null?
      elsif v[0] == 'n'
        return nil

      # Is it true?
      elsif v[0] == 't'
        return true

      # Is it false?
      elsif v[0] == 'f'
        return false

      # Is it number?
      elsif v[0] =~ /^[-0-9]$/
        return ESON.JSONParseWrapper(v)  # use JSON for numbers also

      else
        self.error("ERROR: Invalid token")
      end
    end


    # Parses opened list starting at pos, returns it and moves pos
    def parseList()

      # Spoil next token but do not move
      v = @list[@pos]

      if v == ']'
        @pos += 1 # now we can move
        return [] # list is empty
      end

      # If this is not end initiate result with first value
      result = [self.parseVal()]

      # Read the other values in a loop
      while true
        v = @list[@pos] # Get next token
        @pos += 1

        if v == ']' # If already finished
          return result # return what we have
        end

        # Otherwise, comma should follow
        self.error("ERROR: Expected ',' or ']'") unless v == ','

        x = self.parseVal() # Get next value
        result.push(x)  # And store it
      end
    end


    # Parses opened object starting at pos, returns it and moves pos
    def parseObj()
      v = @list[@pos] # Get next token
      @pos += 1
      result = {}

      # Is this the end?
      if v == '}'
        return {} #object is empty
      end

      # Should start with a string (key)
      self.error("ERROR: Expected string") unless v[0] == "\""

      # and continue with a semicolon
      self.error("ERROR: Expected ':'") unless @list[@pos] == ':'
      @pos += 1

      # then the first value comes and is stored
      result[ESON.JSONParseWrapper(v)] = self.parseVal()

      # Read the other pairs in a loop
      while true
        v = @list[@pos] # Get next token
        @pos += 1

        if v == '}' # If already
          return result # return what we have
        end

        # Otherwise, comma should follow
        self.error("ERROR: Expected ',' or ']'") unless v == ','

        # Get new key and check it is a string
        v = @list[@pos]
        @pos += 1
        self.error("ERROR: Expected string") unless v[0] == "\""

        # Enforce semicolon
        self.error("ERROR: Expected ':'") unless @list[@pos] == ':'

        # Finally, get the value
        result[ESON.JSONParseWrapper(v)] = self.parseVal()
      end
    end
  end


  # Create and expose standard parsing function
  # Tries to use registered handler and use given default_strategy otherwise
  def self.parse(str, default_strategy = nil)
    p = ESON::Parser.new(str)
    p.tag_strategy = Strategies.make_standard_tag_strategy.call(default_strategy)
    p.parse()
  end

  # Create and expose parsing function which ignores tags
  def self.pure_parse(str)
    p = ESON::Parser.new(str)
    p.tag_strategy = Strategies.ignore_tag_strategy
    p.parse()
  end


  # Create and expose parsing function parses tags to ESON.Tag object
  def self.struct_parse(str)
    p = ESON::Parser.new(str)
    p.tag_strategy = Strategies.struct_tag_strategy
    p.parse()
  end
end


