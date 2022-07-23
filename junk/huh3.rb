class Parent
  Const = "foo123"

  def showme
    puts self.class.const_get(:Const)
  end
end


class Child < Parent
  Const = "bar237"
end


x = Child.new
x.showme
