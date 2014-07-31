# =========
# Stringify
# =========


# Stringify overview
# ------------------
#
# ESON.stringify tries to match JSON.stringify behavior.
# Object can define own .toESON() which is preferred to .toJSON() but
# both can be used to define value to be stringified.
# In lists and tags unserializable values (functions, undefined, ...) are
# converted to nulls. In all other cases unserializable values are ignored.
#
# Implementation of stringify concatenates strings only once - at the end.
# During the object searching these strings are pushed to array named prefix.


# Internal stringify function, pushes strings to array
# Returns whether value is serializable
require 'json'

module ESON

  private
  def self.JSONGenerateWrap(value)
    ret = JSON.generate([value])
    return ret[1..ret.length - 2]
  end

  private
  def self._generate(value, prefix)

    notObject=[Fixnum, Float, String, NilClass, TrueClass, FalseClass, Proc]


    #we are interested only in objects not mentioned in notObject array
    unless notObject.include?value.class

      # Object can provide custom value to stringify
      if value.respond_to?("to_eson")
        return _generate(value.to_eson(), prefix)

      # Tag
      elsif value.is_a?ESON::Tag
        prefix.push("#", value.id, ' ')
        unless _generate(value.data, prefix)
          prefix.push("null")
        end
      # Array
      elsif value.is_a?Array
        prefix.push("[")  # Open array
        comma = false # There's no comma before first element
        for x in value
          if comma then prefix.push ',' end
          unless _generate(x, prefix)
            # Inside tags, unserializable values are printed like null-s
            prefix.push("null")
          end
          comma = true  # Separate next element
        end
        prefix.push("]")  # Close object

      # Otherwise, object is supposed to be a hash (unordered map)
      elsif value.is_a?Hash
        prefix.push("{")  # Open object
        comma = false # There's no comma before first element
        value.each do | k, v |
          # To effectively avoid unserializable values,
          # here is some repetitive code which inspects them
          unless notObject.include?v.class
            # Most of the objects should be serializable
            if comma then prefix.push(',') end
            prefix.push(JSONGenerateWrap(k),':')
            unless _generate(v, prefix)
              # This happens only if toESON / toJSON returns unserializable.
              # Supposing this won't happen, handling is not effective.
              if comma then prefix.pop() end
              prefix.pop(2)
            else
              # Serialization was successful
              comma = true  # Separate next element
            end
          else
            # the rest of objects we can directly serialize by JSON
            str = JSONGenerateWrap(v)
            unless str.nil?
              if comma then prefix.push(',') end
              prefix.push(JSONGenerateWrap(k))
              prefix.push(":", str)
              comma = true  # Separate next element
            end
          end
        end
        prefix.push("}")  # Close object

      # Support JSON's custom value
      elsif value.respond_to?("to_json")
        return _generate(value.to_json(), prefix)
      end
      return true
    # All the other types are stringified like JSON
    else
      str = JSONGenerateWrap(value)
      unless str.nil?
        prefix.push(str)
        return true
      else
        return false
      end
    end
  end

  # Public generate function
  # Initializes and concatenates list of output tokens
  def self.generate(value)
    l = []
    if _generate(value, l)
      return l.join('')
    else
      return nil
    end
  end
end


