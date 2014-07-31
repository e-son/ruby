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
  def self._stringify(value, prefix)
    notObject=[Fixnum, Float, String, NilClass, TrueClass, FalseClass, Proc]

    unless notObject.include?value.class
      if value.respond_to?("to_eson")
        return _stringify(value.to_eson(), prefix)

      elsif value.is_a?ESON::Tag
        prefix.push("#", value.id, ' ')
        unless _stringify(value.data, prefix)
          prefix.push("null")
        end

      elsif value.is_a?Array
        prefix.push("[")
        comma = false
        for x in value
          if comma
            prefix.push ','
          end
          unless _stringify(x, prefix)
            prefix.push("null")
          end
          comma = true
        end
        prefix.push("]")
        
      elsif value.is_a?Hash
        prefix.push("{")
        comma = false
        value.each do | k, v |
          unless notObject.include?v.class
            if comma
              prefix.push(',')
            end
            prefix.push(JSONGenerateWrap(k),':')
            unless _stringify(v, prefix)
              if comma
                prefix.pop()
              end
              prefix.pop(2)
            else
              comma = true
            end
          else
            str = JSONGenerateWrap(v)
            unless str.nil?
              if comma
                prefix.push(',')
              end
              prefix.push(JSONGenerateWrap(k))
              prefix.push(":", str)
              comma = true
            end
          end
        end
        prefix.push("}")

      elsif value.respond_to?("to_json")
        return _stringify(value.to_json(), prefix)
      end
      return true
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

  def self.generate(value)
    l = []
    if _stringify(value, l)
      return l.join('')
    else
      return nil
    end
  end
end


