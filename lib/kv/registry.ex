defmodule KV.Registry do
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  def lookup(registry, name) do
    Agent.get(registry, &Map.fetch(&1, name))
  end

  def create(registry, name) do
    Agent.cast(registry, fn names ->
      {:ok, bucket} = KV.Bucket.start_link()
      Map.put(names, name, bucket)
    end)
  end
end
