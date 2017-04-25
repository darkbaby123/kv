defmodule KV.Registry do
  use GenServer

  ### Server

  def init(_) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name}, {names, refs} = state) do
    if Map.has_key?(names, name) do
      {:noreply, state}
    else
      {:ok, bucket} = KV.Bucket.start_link()
      ref = Process.monitor(bucket)
      new_names = Map.put(names, name, bucket)
      new_refs = Map.put(refs, ref, name)
      {:noreply, {new_names, new_refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _, _}, {names, refs}) do
    {name, new_refs} = Map.pop(refs, ref)
    new_names = Map.delete(names, name)
    {:noreply, {new_names, new_refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ### Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def lookup(registry, name) do
    GenServer.call(registry, {:lookup, name})
  end

  def create(registry, name) do
    GenServer.cast(registry, {:create, name})
  end
end
