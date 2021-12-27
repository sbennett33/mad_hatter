defmodule MadHatterWeb.PageLive do
  use MadHatterWeb, :live_view

  alias MadHatter.GameServer

  def mount(_param, _session, socket) do
    data = %{}
    types = %{code: :string}
    params = %{}

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    {:ok, assign(socket, changeset: changeset)}
  end

  def handle_event("new_game", _value, socket) do
    {:ok, code} = GameServer.start()

    {:noreply,
     socket
     #  |> put_flash(:info, "user updated")
     |> redirect(to: Routes.host_path(socket, :show, code))}
  end

  def handle_event("save", %{"join" => %{"code" => code, "name" => name, "fact" => fact}}, socket) do
    :ok = GameServer.submit_fact(code, name, fact)

    {:noreply, redirect(socket, to: Routes.play_path(socket, :show, code, player: name))}
  end
end
