defmodule MadHatterWeb.HostLive do
  use MadHatterWeb, :live_view

  alias MadHatter.GameServer

  alias Phoenix.PubSub

  def mount(%{"code" => code}, _, socket) do
    case GameServer.current_state(code) do
      {:ok, game} ->
        PubSub.subscribe(MadHatter.PubSub, "game:#{code}")

        {:ok, assign(socket, code: code, game: game)}

      {:error, _} ->
        {:ok,
         socket
         #  |> put_flash(:info, "user updated")
         |> redirect(to: Routes.page_path(socket, :index))}
    end
  end

  def handle_event("start_round", _, socket) do
    GameServer.start_round(socket.assigns.code)

    {:noreply, socket}
  end

  def handle_event("new_game", _, socket) do
    {:ok, code} = GameServer.start()

    {:noreply,
     socket
     #  |> put_flash(:info, "user updated")
     |> redirect(to: Routes.host_path(socket, :show, code))}
  end

  def handle_info({:game, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end
end
