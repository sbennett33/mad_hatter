defmodule MadHatter.GameTest do
  use ExUnit.Case

  alias MadHatter.Game

  describe "new/0" do
    test "creates a new game" do
      assert %Game{} = game = Game.new("ASDF")

      assert game.code == "ASDF"
      assert game.hat == []
    end
  end

  describe "submit_factoid/2" do
    test "adds factoids to the hat" do
      player = "Joe"
      fact = "I like blue"

      game =
        Game.new("ASDF")
        |> Game.submit_fact(player, fact)

      assert [{player, fact}] == game.hat
    end
  end

  describe "new_round/1" do
    setup [:new_game, :submit_facts]

    test "starts a new round and draws a factoid from the hat" do
      game =
        Game.new("ASDF")
        |> Game.submit_fact("Joe", "I like blue")
        |> Game.submit_fact("Bob", "I like red")
        |> Game.submit_fact("Jim", "I like green")
        |> Game.submit_fact("Ray", "I like purple")
        |> Game.new_round()

      assert game.current_fact != nil
      assert length(game.hat) == 3
    end

    test "resets round totals for players", %{game: game} do
      game = Game.new_round(game)

      assert map_size(game.round_totals) == 2

      Enum.each(game.round_totals, fn {_player, count} ->
        assert count == 0
      end)
    end

    test "can start multiple rounds" do
      game =
        Game.new("ASDF")
        |> Game.submit_fact("Joe", "I like blue")
        |> Game.submit_fact("Bob", "I like red")
        |> Game.submit_fact("Jim", "I like green")
        |> Game.submit_fact("Ray", "I like purple")
        |> Game.new_round()

      assert game.current_fact != nil
      assert length(game.hat) == 3

      previous_fact = game.current_fact

      game = Game.new_round(game)

      assert game.current_fact != previous_fact
      assert length(game.hat) == 2
    end

    test "cannot start round with an empty hat" do
      assert Game.new("ASDF")
             |> Game.new_round() == {:error, :empty_hat}
    end

    test "returns error once all facts have been drawn" do
      assert Game.new("ASDF")
             |> Game.submit_fact("Joe", "I like blue")
             |> Game.new_round()
             |> Game.new_round() == {:error, :empty_hat}
    end
  end

  describe "guess/2" do
    setup [:new_game, :submit_facts, :start_round]

    test "adds guess to list of guesses", %{game: game} do
      game = Game.guess(game, "Sara", "Joe")

      assert game.guesses == %{"Sara" => "Joe"}
    end

    test "updates guessers guess", %{game: game} do
      game =
        game
        |> Game.guess("Jim", "Joe")
        |> Game.guess("Jim", "Sara")

      assert game.guesses == %{"Jim" => "Sara"}
    end

    test "updates round totals", %{game: game} do
      game =
        game
        |> Game.guess("Joe", "Joe")
        |> Game.guess("Sara", "Joe")
        |> Game.guess("Jenny", "Sara")

      assert game.round_totals == %{"Joe" => 2, "Sara" => 1}
    end

    test "returns error on invalid guess", %{game: game} do
      assert Game.guess(game, "Joe", "Jenny") == {:error, :bad_guess}
    end

    test "returns error when trying to guess before the round has started" do
      assert Game.new("ASDF")
             |> Game.guess("Joe", "Jim") == {:error, :not_started}
    end
  end

  defp new_game(_) do
    [game: Game.new("ASDF")]
  end

  defp submit_facts(%{game: game}) do
    game =
      game
      |> Game.submit_fact("Joe", "I like blue")
      |> Game.submit_fact("Sara", "I like orange")

    [game: game]
  end

  defp start_round(%{game: game}) do
    [game: Game.new_round(game)]
  end
end
