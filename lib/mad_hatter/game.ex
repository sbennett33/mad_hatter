defmodule MadHatter.Game do
  defstruct code: "",
            players: [],
            hat: [],
            current_fact: nil,
            guesses: %{},
            round_totals: %{},
            round_time_remaining: 0,
            state: :not_started

  @round_duration 30_000

  def new(code) do
    %__MODULE__{
      code: code
    }
  end

  def submit_fact(game, player, fact) do
    if !player_found?(game, player) do
      %{game | hat: [{player, fact} | game.hat], players: [player | game.players]}
    else
      game
    end
  end

  def new_round(%{hat: []}), do: {:error, :empty_hat}

  def new_round(game) do
    round_totals =
      Enum.map(game.players, fn player ->
        {player, 0}
      end)
      |> Enum.into(%{})

    [random_fact | hat] = Enum.shuffle(game.hat)

    Process.send_after(self(), :tick, 1000)

    %{
      game
      | hat: hat,
        current_fact: random_fact,
        guesses: %{},
        round_totals: round_totals,
        round_time_remaining: @round_duration,
        state: :round_running
    }
  end

  def guess(%{current_fact: nil}, _guess, _guesser), do: {:error, :not_started}

  def guess(%{state: state}, _guess, _guesser) when state != :round_running,
    do: {:error, :not_running}

  def guess(game, guesser, guess) do
    guesses = put_in(game.guesses, [guesser], guess)

    round_totals =
      Enum.map(game.players, fn player ->
        score =
          Enum.reduce(guesses, 0, fn {_player, guess}, acc ->
            if player == guess do
              acc + 1
            else
              acc
            end
          end)

        {player, score}
      end)
      |> Enum.into(%{})

    %{game | guesses: guesses, round_totals: round_totals}
  end

  def tick(%{round_time_remaining: 0, hat: []} = game) do
    %{game | state: :game_over}
  end

  def tick(%{round_time_remaining: 0} = game) do
    %{game | state: :round_over}
  end

  def tick(%{round_time_remaining: time} = game) do
    Process.send_after(self(), :tick, 1000)
    %{game | round_time_remaining: time - 1000}
  end

  def player_found?(%{players: players}, player) do
    Enum.member?(players, player)
  end
end
