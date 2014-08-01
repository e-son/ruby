
##
# = JavaScript Object Notation (ESON)
#
# ESON is a lightweight data-interchange format. It is easy for us
# humans to read and write. Plus, equally simple for machines to generate or parse.rb.
# ESON is completely language agnostic, making it the ideal interchange format.
#
# Built on two universally available structures:
#   1. A collection of name/value pairs. Often referred to as an _object_, hash table, record, struct, keyed list, or associative array.
#   2. An ordered list of values. More commonly called an _array_, vector, sequence or list.
#
# To read more about ESON visit: http://eson.org
#
# == Parsing ESON
#
# To parse.rb a ESON string received by another application or generated within
# your existing application:
#
#   require 'eson'
#
#   my_hash = ESON.parse.rb('{"hello": "goodbye"}')
#   puts my_hash["hello"] => "goodbye"
#
# Notice the extra quotes <tt>''</tt> around the hash notation. Ruby expects
# the argument to be a string and can't convert objects like a hash or array.
#
# Ruby converts your string into a hash
#
# == Generating ESON
#
# Creating a ESON string for communication or serialization is
# just as simple.
#
#   require 'eson'
#
#   my_hash = {:hello => "goodbye"}
#   puts ESON.generate(my_hash) => "{\"hello\":\"goodbye\"}"
#
# Or an alternative way:
#
#   require 'eson'
#   puts {:hello => "goodbye"}.to_eson => "{\"hello\":\"goodbye\"}"
#
# <tt>ESON.generate</tt> only allows objects or arrays to be converted
# to ESON syntax. <tt>to_eson</tt>, however, accepts many Ruby classes
# even though it acts only as a method for serialization:
#
#   require 'eson'
#
#   1.to_eson => "1"
#
module ESON
  require_relative './ESON/version'
  require_relative 'ESON/tag'
  require_relative 'ESON/registry'
  require_relative 'ESON/generate'

  class << self
    attr_accessor :tags
  end
  self.tags = {}
end
