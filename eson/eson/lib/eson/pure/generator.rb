module ESON
  MAP = {
    "\x0" => '\u0000',
    "\x1" => '\u0001',
    "\x2" => '\u0002',
    "\x3" => '\u0003',
    "\x4" => '\u0004',
    "\x5" => '\u0005',
    "\x6" => '\u0006',
    "\x7" => '\u0007',
    "\b"  =>  '\b',
    "\t"  =>  '\t',
    "\n"  =>  '\n',
    "\xb" => '\u000b',
    "\f"  =>  '\f',
    "\r"  =>  '\r',
    "\xe" => '\u000e',
    "\xf" => '\u000f',
    "\x10" => '\u0010',
    "\x11" => '\u0011',
    "\x12" => '\u0012',
    "\x13" => '\u0013',
    "\x14" => '\u0014',
    "\x15" => '\u0015',
    "\x16" => '\u0016',
    "\x17" => '\u0017',
    "\x18" => '\u0018',
    "\x19" => '\u0019',
    "\x1a" => '\u001a',
    "\x1b" => '\u001b',
    "\x1c" => '\u001c',
    "\x1d" => '\u001d',
    "\x1e" => '\u001e',
    "\x1f" => '\u001f',
    '"'   =>  '\"',
    '\\'  =>  '\\\\',
  } # :nodoc:

  # Convert a UTF8 encoded Ruby string _string_ to a ESON string, encoded with
  # UTF16 big endian characters as \u????, and return it.
  if defined?(::Encoding)
    def utf8_to_eson(string) # :nodoc:
      string = string.dup
      string.force_encoding(::Encoding::ASCII_8BIT)
      string.gsub!(/["\\\x0-\x1f]/) { MAP[$&] }
      string.force_encoding(::Encoding::UTF_8)
      string
    end

    def utf8_to_eson_ascii(string) # :nodoc:
      string = string.dup
      string.force_encoding(::Encoding::ASCII_8BIT)
      string.gsub!(/["\\\x0-\x1f]/n) { MAP[$&] }
      string.gsub!(/(
                      (?:
                        [\xc2-\xdf][\x80-\xbf]    |
                        [\xe0-\xef][\x80-\xbf]{2} |
                        [\xf0-\xf4][\x80-\xbf]{3}
                      )+ |
                      [\x80-\xc1\xf5-\xff]       # invalid
                    )/nx) { |c|
                      c.size == 1 and raise GeneratorError, "invalid utf8 byte: '#{c}'"
                      s = ESON.iconv('utf-16be', 'utf-8', c).unpack('H*')[0]
                      s.force_encoding(::Encoding::ASCII_8BIT)
                      s.gsub!(/.{4}/n, '\\\\u\&')
                      s.force_encoding(::Encoding::UTF_8)
                    }
      string.force_encoding(::Encoding::UTF_8)
      string
    rescue => e
      raise GeneratorError.wrap(e)
    end

    def valid_utf8?(string)
      encoding = string.encoding
      (encoding == Encoding::UTF_8 || encoding == Encoding::ASCII) &&
        string.valid_encoding?
    end
    module_function :valid_utf8?
  else
    def utf8_to_eson(string) # :nodoc:
      string.gsub(/["\\\x0-\x1f]/n) { MAP[$&] }
    end

    def utf8_to_eson_ascii(string) # :nodoc:
      string = string.gsub(/["\\\x0-\x1f]/) { MAP[$&] }
      string.gsub!(/(
                      (?:
                        [\xc2-\xdf][\x80-\xbf]    |
                        [\xe0-\xef][\x80-\xbf]{2} |
                        [\xf0-\xf4][\x80-\xbf]{3}
                      )+ |
                      [\x80-\xc1\xf5-\xff]       # invalid
                    )/nx) { |c|
        c.size == 1 and raise GeneratorError, "invalid utf8 byte: '#{c}'"
        s = ESON.iconv('utf-16be', 'utf-8', c).unpack('H*')[0]
        s.gsub!(/.{4}/n, '\\\\u\&')
      }
      string
    rescue => e
      raise GeneratorError.wrap(e)
    end

    def valid_utf8?(string)
      string =~
         /\A( [\x09\x0a\x0d\x20-\x7e]         # ASCII
         | [\xc2-\xdf][\x80-\xbf]             # non-overlong 2-byte
         |  \xe0[\xa0-\xbf][\x80-\xbf]        # excluding overlongs
         | [\xe1-\xec\xee\xef][\x80-\xbf]{2}  # straight 3-byte
         |  \xed[\x80-\x9f][\x80-\xbf]        # excluding surrogates
         |  \xf0[\x90-\xbf][\x80-\xbf]{2}     # planes 1-3
         | [\xf1-\xf3][\x80-\xbf]{3}          # planes 4-15
         |  \xf4[\x80-\x8f][\x80-\xbf]{2}     # plane 16
        )*\z/nx
    end
  end
  module_function :utf8_to_eson, :utf8_to_eson_ascii, :valid_utf8?


  module Pure
    module Generator
      # This class is used to create State instances, that are use to hold data
      # while generating a ESON text from a Ruby data structure.
      class State
        # Creates a State object from _opts_, which ought to be Hash to create
        # a new State instance configured by _opts_, something else to create
        # an unconfigured instance. If _opts_ is a State object, it is just
        # returned.
        def self.from_state(opts)
          case
          when self === opts
            opts
          when opts.respond_to?(:to_hash)
            new(opts.to_hash)
          when opts.respond_to?(:to_h)
            new(opts.to_h)
          else
            SAFE_STATE_PROTOTYPE.dup
          end
        end

        # Instantiates a new State object, configured by _opts_.
        #
        # _opts_ can have the following keys:
        #
        # * *indent*: a string used to indent levels (default: ''),
        # * *space*: a string that is put after, a : or , delimiter (default: ''),
        # * *space_before*: a string that is put before a : pair delimiter (default: ''),
        # * *object_nl*: a string that is put at the end of a ESON object (default: ''),
        # * *array_nl*: a string that is put at the end of a ESON array (default: ''),
        # * *check_circular*: is deprecated now, use the :max_nesting option instead,
        # * *max_nesting*: sets the maximum level of data structure nesting in
        #   the generated ESON, max_nesting = 0 if no maximum should be checked.
        # * *allow_nan*: true if NaN, Infinity, and -Infinity should be
        #   generated, otherwise an exception is thrown, if these values are
        #   encountered. This options defaults to false.
        # * *quirks_mode*: Enables quirks_mode for parser, that is for example
        #   generating single ESON values instead of documents is possible.
        def initialize(opts = {})
          @indent                = ''
          @space                 = ''
          @space_before          = ''
          @object_nl             = ''
          @array_nl              = ''
          @allow_nan             = false
          @ascii_only            = false
          @quirks_mode           = false
          @buffer_initial_length = 1024
          configure opts
        end

        # This string is used to indent levels in the ESON text.
        attr_accessor :indent

        # This string is used to insert a space between the tokens in a ESON
        # string.
        attr_accessor :space

        # This string is used to insert a space before the ':' in ESON objects.
        attr_accessor :space_before

        # This string is put at the end of a line that holds a ESON object (or
        # Hash).
        attr_accessor :object_nl

        # This string is put at the end of a line that holds a ESON array.
        attr_accessor :array_nl

        # This integer returns the maximum level of data structure nesting in
        # the generated ESON, max_nesting = 0 if no maximum is checked.
        attr_accessor :max_nesting

        # If this attribute is set to true, quirks mode is enabled, otherwise
        # it's disabled.
        attr_accessor :quirks_mode

        # :stopdoc:
        attr_reader :buffer_initial_length

        def buffer_initial_length=(length)
          if length > 0
            @buffer_initial_length = length
          end
        end
        # :startdoc:

        # This integer returns the current depth data structure nesting in the
        # generated ESON.
        attr_accessor :depth

        def check_max_nesting # :nodoc:
          return if @max_nesting.zero?
          current_nesting = depth + 1
          current_nesting > @max_nesting and
            raise NestingError, "nesting of #{current_nesting} is too deep"
        end

        # Returns true, if circular data structures are checked,
        # otherwise returns false.
        def check_circular?
          !@max_nesting.zero?
        end

        # Returns true if NaN, Infinity, and -Infinity should be considered as
        # valid ESON and output.
        def allow_nan?
          @allow_nan
        end

        # Returns true, if only ASCII characters should be generated. Otherwise
        # returns false.
        def ascii_only?
          @ascii_only
        end

        # Returns true, if quirks mode is enabled. Otherwise returns false.
        def quirks_mode?
          @quirks_mode
        end

        # Configure this State instance with the Hash _opts_, and return
        # itself.
        def configure(opts)
          if opts.respond_to?(:to_hash)
            opts = opts.to_hash
          elsif opts.respond_to?(:to_h)
            opts = opts.to_h
          else
            raise TypeError, "can't convert #{opts.class} into Hash"
          end
          for key, value in opts
            instance_variable_set "@#{key}", value
          end
          @indent                = opts[:indent] if opts.key?(:indent)
          @space                 = opts[:space] if opts.key?(:space)
          @space_before          = opts[:space_before] if opts.key?(:space_before)
          @object_nl             = opts[:object_nl] if opts.key?(:object_nl)
          @array_nl              = opts[:array_nl] if opts.key?(:array_nl)
          @allow_nan             = !!opts[:allow_nan] if opts.key?(:allow_nan)
          @ascii_only            = opts[:ascii_only] if opts.key?(:ascii_only)
          @depth                 = opts[:depth] || 0
          @quirks_mode           = opts[:quirks_mode] if opts.key?(:quirks_mode)
          @buffer_initial_length ||= opts[:buffer_initial_length]

          if !opts.key?(:max_nesting) # defaults to 100
            @max_nesting = 100
          elsif opts[:max_nesting]
            @max_nesting = opts[:max_nesting]
          else
            @max_nesting = 0
          end
          self
        end
        alias merge configure

        # Returns the configuration instance variables as a hash, that can be
        # passed to the configure method.
        def to_h
          result = {}
          for iv in instance_variables
            iv = iv.to_s[1..-1]
            result[iv.to_sym] = self[iv]
          end
          result
        end

        alias to_hash to_h

        # Generates a valid ESON document from object +obj+ and returns the
        # result. If no valid ESON document can be created this method raises a
        # GeneratorError exception.
        def generate(obj)
          result = obj.to_eson(self)
          ESON.valid_utf8?(result) or raise GeneratorError,
            "source sequence #{result.inspect} is illegal/malformed utf-8"
          unless @quirks_mode
            unless result =~ /\A\s*\[/ && result =~ /\]\s*\Z/ ||
              result =~ /\A\s*\{/ && result =~ /\}\s*\Z/
            then
              raise GeneratorError, "only generation of ESON objects or arrays allowed"
            end
          end
          result
        end

        # Return the value returned by method +name+.
        def [](name)
          if respond_to?(name)
            __send__(name)
          else
            instance_variable_get("@#{name}")
          end
        end

        def []=(name, value)
          if respond_to?(name_writer = "#{name}=")
            __send__ name_writer, value
          else
            instance_variable_set "@#{name}", value
          end
        end
      end

      module GeneratorMethods
        module Object
          # Converts this object to a string (calling #to_s), converts
          # it to a ESON string, and returns the result. This is a fallback, if no
          # special method #to_eson was defined for some object.
          def to_eson(*) to_s.to_eson end
        end

        module Hash
          # Returns a ESON string containing a ESON object, that is unparsed from
          # this Hash instance.
          # _state_ is a ESON::State object, that can also be used to configure the
          # produced ESON string output further.
          # _depth_ is used to find out nesting depth, to indent accordingly.
          def to_eson(state = nil, *)
            state = State.from_state(state)
            state.check_max_nesting
            eson_transform(state)
          end

          private

          def eson_shift(state)
            state.object_nl.empty? or return ''
            state.indent * state.depth
          end

          def eson_transform(state)
            delim = ','
            delim << state.object_nl
            result = '{'
            result << state.object_nl
            depth = state.depth += 1
            first = true
            indent = !state.object_nl.empty?
            each { |key,value|
              result << delim unless first
              result << state.indent * depth if indent
              result << key.to_s.to_eson(state)
              result << state.space_before
              result << ':'
              result << state.space
              result << value.to_eson(state)
              first = false
            }
            depth = state.depth -= 1
            result << state.object_nl
            result << state.indent * depth if indent
            result << '}'
            result
          end
        end

        module Array
          # Returns a ESON string containing a ESON array, that is unparsed from
          # this Array instance.
          # _state_ is a ESON::State object, that can also be used to configure the
          # produced ESON string output further.
          def to_eson(state = nil, *)
            state = State.from_state(state)
            state.check_max_nesting
            eson_transform(state)
          end

          private

          def eson_transform(state)
            delim = ','
            delim << state.array_nl
            result = '['
            result << state.array_nl
            depth = state.depth += 1
            first = true
            indent = !state.array_nl.empty?
            each { |value|
              result << delim unless first
              result << state.indent * depth if indent
              result << value.to_eson(state)
              first = false
            }
            depth = state.depth -= 1
            result << state.array_nl
            result << state.indent * depth if indent
            result << ']'
          end
        end

        module Integer
          # Returns a ESON string representation for this Integer number.
          def to_eson(*) to_s end
        end

        module Float
          # Returns a ESON string representation for this Float number.
          def to_eson(state = nil, *)
            state = State.from_state(state)
            case
            when infinite?
              if state.allow_nan?
                to_s
              else
                raise GeneratorError, "#{self} not allowed in ESON"
              end
            when nan?
              if state.allow_nan?
                to_s
              else
                raise GeneratorError, "#{self} not allowed in ESON"
              end
            else
              to_s
            end
          end
        end

        module String
          if defined?(::Encoding)
            # This string should be encoded with UTF-8 A call to this method
            # returns a ESON string encoded with UTF16 big endian characters as
            # \u????.
            def to_eson(state = nil, *args)
              state = State.from_state(state)
              if encoding == ::Encoding::UTF_8
                string = self
              else
                string = encode(::Encoding::UTF_8)
              end
              if state.ascii_only?
                '"' << ESON.utf8_to_eson_ascii(string) << '"'
              else
                '"' << ESON.utf8_to_eson(string) << '"'
              end
            end
          else
            # This string should be encoded with UTF-8 A call to this method
            # returns a ESON string encoded with UTF16 big endian characters as
            # \u????.
            def to_eson(state = nil, *args)
              state = State.from_state(state)
              if state.ascii_only?
                '"' << ESON.utf8_to_eson_ascii(self) << '"'
              else
                '"' << ESON.utf8_to_eson(self) << '"'
              end
            end
          end

          # Module that holds the extinding methods if, the String module is
          # included.
          module Extend
            # Raw Strings are ESON Objects (the raw bytes are stored in an
            # array for the key "raw"). The Ruby String can be created by this
            # module method.
            def eson_create(o)
              o['raw'].pack('C*')
            end
          end

          # Extends _modul_ with the String::Extend module.
          def self.included(modul)
            modul.extend Extend
          end

          # This method creates a raw object hash, that can be nested into
          # other data structures and will be unparsed as a raw string. This
          # method should be used, if you want to convert raw strings to ESON
          # instead of UTF-8 strings, e. g. binary data.
          def to_eson_raw_object
            {
              ESON.create_id  => self.class.name,
              'raw'           => self.unpack('C*'),
            }
          end

          # This method creates a ESON text from the result of
          # a call to to_eson_raw_object of this String.
          def to_eson_raw(*args)
            to_eson_raw_object.to_eson(*args)
          end
        end

        module TrueClass
          # Returns a ESON string for true: 'true'.
          def to_eson(*) 'true' end
        end

        module FalseClass
          # Returns a ESON string for false: 'false'.
          def to_eson(*) 'false' end
        end

        module NilClass
          # Returns a ESON string for nil: 'null'.
          def to_eson(*) 'null' end
        end
      end
    end
  end
end
