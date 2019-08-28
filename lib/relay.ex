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

  def close_lid(pid, chamber) do
    GenServer.cast(pid, {:close, chamber})
  end

  def state(pid, valve) do
    GenServer.call(pid, {:status, valve})
  end

  def relay_status(pid, relay) do
    GenServer.call(pid, {:relay_state, relay})
  end

  def init(_) do
    {:ok, icp} = IcpDas.start_link
    {:ok, %{icp: icp}, {:continue, :load_relay_mapping}}
  end

  def handle_continue(:load_relay_mapping, state) do
    chambers = load_relay_file()

    relays = extract_relays(chambers)

    #TODO set all relays to zero or query relays for current status

    new_state = state
                |> Map.put(:chambers, chambers)
                |> Map.put(:relays, relays)

    {:noreply, new_state}
  end

  def handle_call({:lookup, chamber}, _from, state) do
    {:reply, Map.fetch(state[:chambers], chamber), state}
  end

  def handle_call({:relay_state, relay}, _from, state) do
    {:reply, IcpDas.state(state[:icp_das], relay), state}
  end

  def handle_cast({:close, chamber}, state) do
      chamber = Map.fetch(state[:chambers], chamber)
      valve = on(chamber["lid"], state[:icp])
    # TODO  update the data
    {:noreply, state}
  end

  def on({relay, _state}=_valve, icp) do
    icp.set(relay, 1)
    {relay, :on}
  end

  def off({relay, _state} = _valve, icp) do
    icp.set(relay, 0)
    {relay, :off}
  end

  def extract_relays(chambers) do
    chambers["chamber"] |> Enum.map(fn({_key, x})-> x end ) |> Enum.flat_map(fn(x) -> Enum.map(x, fn({_key,y}) -> {y, :off} end) end)
  end

  def load_relay_file() do
    {:ok, data} = File.read(Path.join(:code.priv_dir(:relay), "relay.toml"))
    {:ok, chamber} = Toml.decode(data)
    chamber
  end

  def update_relays(relay_map) do
    relay_map
    |> Enum.each(fn(x) -> update_relay(x) end)
  end

  def update_relay({relay, _state}) do
    IO.inspect relay
  end

end
