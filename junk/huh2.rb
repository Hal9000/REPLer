class Parent
  @help = "foo123"

  def showme
    puts self.class.class_eval { @help }
  end
end


class Child < Parent
  @help = "bar237"
end


x = Child.new
x.showme
