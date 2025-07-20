defmodule Dogfishing.Scorekeeper do
  use Agent

  def start_link([]) do
    start_link({0, 0})
  end

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def right, do: elem(value(), 0)
  def wrong, do: elem(value(), 1)
  def total, do: right() + wrong()
  def ratio, do: right() / total()

  def increment_right do
    Agent.update(__MODULE__, &(put_elem(&1, 0, elem(&1, 0) + 1)))
  end

  def increment_wrong do
    Agent.update(__MODULE__, &(put_elem(&1, 1, elem(&1, 1) + 1)))
  end
end
