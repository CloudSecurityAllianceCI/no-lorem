require 'faker'

class Cat
  attr_reader :name

  def initialize
    @name = Faker::Creature::Cat.name
  end

  def story
    "lorem ipsum"
  end
end

puts "I'm a cat and my name is #{Cat.new.name}"
