def fib(n)
  if n == 0
    return false
  elsif n == 1
    return true
  else
    return {'first' => fib(n - 1), 'second' => fib(n-2)}

  end
end


def num_list(l)
  (1..l).to_a
end


def obj_list(l)
  num_list(l).to_a.collect{|x| {"text" => "Foo", "id" => x} }
end


class Generate
  def each
    yield "true", true
    yield "false", false
    yield "null", nil
    yield "number", 42
    yield "string", "I hate using \\ to write \""

    for i in (0..8)
      yield "Fib #{i * 2}", fib(i * 2)
    end

    for i in [0, 1, 5, 10, 50, 100]
      yield "ObjList #{i}", obj_list(i)
    end

    for i in [0, 1, 5, 10, 50, 100, 1000, 10000]
      yield "NumList #{i}", num_list(i)
    end
  end
end

=begin
x = Generate.new()

x.each do |x|
  p x
end

=end