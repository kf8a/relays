defmodule Relay do
  @moduledoc """
  Documentation for Relay.
  """

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def lookup(pid, chamber) do
    GenServer.call(pid, {:lookup, chamber})
  end

  def state(pid, chamber) do
  end

  def init(_) do
    {:ok, icp} = IcpDas.start_link
    {:ok, %{icp: icp}, {:continue, :load_relay_mapping}}
  end

  def handle_continue(:load_relay_mapping, state) do
    {:ok, data} = File.read(Path.join(:code.priv_dir(:relay), "relay.toml"))
    {:ok, chamber} = Toml.decode(data)
    chamber_with_status = Enum.map(chamber["chamber"], fn({k,v}) -> {k, Enum.map(v, fn({k,v})-> {k,{v, :off}} end) |> Map.new } end) |> Map.new

    #TODO set all relays to zero or query relays for current status

    {:noreply, Map.put(state, :chambers, chamber_with_status)}
  end

  def handle_call({:lookup, chamber}, _from, state) do
    {:reply, Map.fetch(state[:chambers], chamber), state}
  end
end
