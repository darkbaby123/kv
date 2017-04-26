defmodule KV.Registry do
  use GenServer

  ### Server

  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:create, name}, _, {names, refs} = state) do
    case lookup(names, name) do
      {:ok, bucket} ->
        {:reply, bucket, state}
      :error ->
        {:ok, bucket} = KV.Bucket.Supervisor.start_bucket()
        ref = Process.monitor(bucket)
        new_refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, bucket})
        {:reply, bucket, {names, new_refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _, _}, {names, refs}) do
    {name, new_refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, new_refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ### Client

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def lookup(registry, name) do
    case :ets.lookup(registry, name) do
      [{^name, value}] -> {:ok, value}
      _ -> :error
    end
  end

  def create(registry, name) do
    GenServer.call(registry, {:create, name})
  end
end
