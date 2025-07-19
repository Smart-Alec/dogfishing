defmodule DogfishingTest do
  use ExUnit.Case
  doctest Dogfishing

  test "greets the world" do
    assert Dogfishing.hello() == :world
  end
end
