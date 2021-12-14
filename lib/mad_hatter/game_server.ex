defmodule MadHatter.GameServer do
  use GenServer

  alias __MODULE__
  alias MadHatter.Game
  alias Phoenix.PubSub

  require Logger

  def start() do
    with {:ok, code} <- generate_game_code(),
         Horde.DynamicSupervisor.start_child(
           MadHatter.DistributedSupervisor,
           {GameServer, [name: code]}
         ) do
      Logger.info("Started game server #{inspect(code)}")
      {:ok, code}
    end
  end

  def submit_fact(game_code, player, fact) do
    GenServer.call(via_tuple(game_code), {:submit_fact, player, fact})
  end

  def start_round(game_code) do
    GenServer.call(via_tuple(game_code), :start_round)
  end

  def guess(game_code, guesser, guess) do
    GenServer.call(via_tuple(game_code), {:guess, guesser, guess})
  end

  def current_state(game_code) do
    cond do
      server_found?(game_code) ->
        GenServer.call(via_tuple(game_code), :current_state)

      true ->
        {:error, :game_not_found}
    end
  end

  defp generate_game_code() do
    codes = Enum.map(1..10, fn _ -> do_generate_code() end)

    case Enum.find(codes, &(!GameServer.server_found?(&1))) do
      nil ->
        # no unused game code found. Report server busy, try again later.
        {:error, :no_free_code}

      code ->
        {:ok, code}
    end
  end

  defp do_generate_code do
    range = ?A..?Z

    range
    |> Enum.take_random(4)
    |> to_string()
  end

  def server_found?(game_code) do
    # Look up the game in the registry. Return if a match is found.
    case Horde.Registry.lookup(MadHatter.GameRegistry, game_code) do
      [] -> false
      [{pid, _} | _] when is_pid(pid) -> true
    end
  end

  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    %{
      id: "#{GameServer}_#{name}",
      start: {GameServer, :start_link, [name]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  @doc """
  Start a GameServer with the specified game code as the name.
  """
  def start_link(name) do
    case GenServer.start_link(GameServer, name, name: via_tuple(name)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info(
          "Already started GameServer #{inspect(name)} at #{inspect(pid)}, returning :ignore"
        )

        :ignore
    end
  end

  defp via_tuple(code), do: {:via, Horde.Registry, {MadHatter.GameRegistry, code}}

  def init(code) do
    {:ok, Game.new(code)}
  end

  def handle_call({:submit_fact, player, fact}, _, game) do
    game = Game.submit_fact(game, player, fact)

    broadcast_game_state(game)

    {:reply, :ok, game}
  end

  def handle_call(:start_round, _, game) do
    case Game.new_round(game) do
      %Game{} = game ->
        {:reply, :ok, game}

      {:error, reason} = error ->
        Logger.error("Failed to start game. Error: #{inspect(reason)}")
        {:reply, error, game}
    end
  end

  def handle_call({:guess, guesser, guess}, _, game) do
    case Game.guess(game, guesser, guess) do
      %Game{} = game ->
        broadcast_game_state(game)
        {:reply, :ok, game}

      {:error, reason} = error ->
        Logger.error("Failed to submit guess. Error: #{inspect(reason)}")
        {:reply, error, game}
    end
  end

  def handle_call(:current_state, _, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_info(:tick, game) do
    game = Game.tick(game)

    broadcast_game_state(game)

    {:noreply, game}
  end

  defp broadcast_game_state(%Game{} = game) do
    PubSub.broadcast(MadHatter.PubSub, "game:#{game.code}", {:game, game})
  end
end
