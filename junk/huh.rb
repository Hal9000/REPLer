class Parent
  Const = "foo123"

  def showme
    puts Const
  end
end


class Child < Parent
  Const = "bar237"
end


x = Child.new
x.showme
