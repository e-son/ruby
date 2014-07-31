# ========
# Registry
# ========


# Tag parsing handlers
# ----------------------
#
# Tag parsing handler is a function bound to the tag identifier, which takes
# parsed data and returns object that is result of tag parsing.
# They are used by standard parse.rb strategy.


# Tag tree
# --------
#
# Tag tree is structure where tag handlers are organized. It's a tree composed
# of namespaces which can contain other namespaces or handlers.
# Namespace is implemented by objects. Tree elements can be addressed
# by paths. Path is a string of object keys needed to be accessed in order to
# the element separated by slash.


# Get tree element by it's path

module ESON
  def self.resolveTag(path)
    tokens = path.split('/')
    cur = self.tags
    for t in tokens
      # 'cur' should be a registered namespace, so we can get its child
      if cur.nil?
        # path does not exist
        return nil
      end
      cur = cur[t]
    end
    return cur
  end


  # Deletes entire subtree with root in path if exists
  def self.deleteTag(path)
    tokens = path.split('/')
    cur = self.tags
    last = nil
    for t in tokens
      # 'cur' should be a registered namespace, so we can get its child
      if cur.nil?
        return
      end
      last = cur
      cur = cur[t]
    end

    # 'last' is path's final namespace
    # 'cur' is deleted thing
    last.delete(tokens.last)
  end


  # Register new function / namespace with the tag
  # Parent namespace must exist but path must be free
  def self.registerTag(path, elem)
    tokens = path.split('/')
    cur = self.tags
    last = nil
    for t in tokens
      # 'cur' should be a registered namespace, so we can get its child
      if cur.nil?
        raise "ERROR: Parent namespace not registered"
      end
      last = cur
      cur = cur[t]
    end

    unless cur.nil?
      raise "ERROR: Path '#{path}' is already registered"
    end

    # 'last' is path's final namespace
    # 'cur' should be undefined in order to not overwrite it
    last[tokens.last] = elem
  end

end

