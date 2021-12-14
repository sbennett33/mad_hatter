defmodule MadHatterWeb.PlayLive do
  use MadHatterWeb, :live_view

  alias MadHatter.GameServer
  alias Phoenix.PubSub

  def mount(%{"code" => code, "player" => player}, _, socket) do
    case GameServer.current_state(code) do
      {:ok, game} ->
        PubSub.subscribe(MadHatter.PubSub, "game:#{code}")

        players = Enum.filter(game.players, &(&1 != player))

        {:ok, assign(socket, player: player, code: code, players: players, game: game)}

      {:error, _} ->
        {:ok,
         socket
         #  |> put_flash(:info, "user updated")
         |> redirect(to: Routes.page_path(socket, :index))}
    end
  end

  def handle_event("guess", %{"guesser" => guesser, "guess" => guess}, socket) do
    GameServer.guess(socket.assigns.code, guesser, guess)

    {:noreply, socket}
  end

  def handle_info({:game, game}, socket) do
    players = Enum.filter(game.players, &(&1 != socket.assigns.player))
    {:noreply, assign(socket, players: players, game: game)}
  end
end
