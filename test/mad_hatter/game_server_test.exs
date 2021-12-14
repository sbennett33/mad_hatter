defmodule MadHatter.GameServerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias MadHatter.Game
  alias MadHatter.GameServer

  alias Phoenix.PubSub

  describe "start/0" do
    test "starts a new game and adds it to the registry" do
      assert {:ok, code} = GameServer.start()

      assert [{pid, _} | _] = Horde.Registry.lookup(MadHatter.GameRegistry, code)
      assert is_pid(pid)
      assert %Game{} = :sys.get_state(pid)
    end
  end

  describe "submit_fact/3" do
    setup [:create_game, :lookup_pid]

    test "adds fact to game hat", %{code: code, pid: pid} do
      player = "Joe"
      fact = "I like blue"

      GameServer.submit_fact(code, player, fact)

      assert %Game{hat: hat} = :sys.get_state(pid)

      assert [{player, fact}] == hat
    end
  end

  describe "start_round/1 with facts" do
    setup [:create_game, :add_facts, :lookup_pid]

    test "draws a fact from the hat", %{code: code, pid: pid} do
      game = :sys.get_state(pid)

      assert length(game.hat) == 2
      refute game.current_fact

      GameServer.start_round(code)

      game = :sys.get_state(pid)

      assert length(game.hat) == 1
      assert game.current_fact
    end
  end

  describe "start_round/1 without facts" do
    setup [:create_game]

    test "returns error", %{code: code} do
      assert capture_log(fn ->
               assert GameServer.start_round(code) == {:error, :empty_hat}
             end) =~ "Failed to start game"
    end
  end

  describe "guess/3" do
    setup [:create_game, :add_facts, :start_round, :lookup_pid]

    test "adds guess to list of guesses", %{code: code, pid: pid} do
      game = :sys.get_state(pid)

      assert game.guesses == %{}

      GameServer.guess(code, "Jim", "Sara")

      game = :sys.get_state(pid)

      assert map_size(game.guesses) == 1
    end

    test "can add multiple guesses", %{code: code, pid: pid} do
      GameServer.guess(code, "Jim", "Sara")
      GameServer.guess(code, "Joe", "Joe")
      GameServer.guess(code, "Bob", "Joe")

      game = :sys.get_state(pid)

      assert map_size(game.guesses) == 3
    end

    test "allows users to change their guess", %{code: code, pid: pid} do
      GameServer.guess(code, "Jim", "Sara")
      GameServer.guess(code, "Jim", "Joe")

      game = :sys.get_state(pid)

      assert map_size(game.guesses) == 1
    end

    test "returns error on bad guess", %{code: code} do
      assert capture_log(fn ->
               assert {:error, :bad_guess} = GameServer.guess(code, "Jim", "Not a player")
             end)
    end

    test "broadcasts game state after each guess", %{code: code} do
      PubSub.subscribe(MadHatter.PubSub, "game:#{code}")

      :ok = GameServer.guess(code, "Jim", "Sara")

      assert {:messages, [message | _]} = Process.info(self(), :messages)
      assert {:game, %Game{} = game} = message

      assert game.code == code
      assert map_size(game.guesses) == 1
      assert game.round_totals["Sara"] == 1
    end
  end

  defp create_game(_context) do
    {:ok, code} = GameServer.start()

    [code: code]
  end

  defp add_facts(%{code: code}) do
    player_1 = "Joe"
    player_1_fact = "I like blue"

    player_2 = "Sara"
    player_2_fact = "I like orange"

    GameServer.submit_fact(code, player_1, player_1_fact)
    GameServer.submit_fact(code, player_2, player_2_fact)
  end

  defp start_round(%{code: code}) do
    GameServer.start_round(code)
  end

  defp lookup_pid(%{code: code}) do
    [{pid, _} | _] = Horde.Registry.lookup(MadHatter.GameRegistry, code)

    [pid: pid]
  end
end
