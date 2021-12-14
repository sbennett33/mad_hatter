defmodule MadHatterWeb.JoinLive do
  use MadHatterWeb, :live_view

  alias MadHatter.GameServer

  def mount(%{"code" => code}, _, socket) do
    data = %{}
    types = %{code: :string, name: :string, fact: :string}
    params = %{code: code}

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    {:ok, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"fact" => %{"code" => code, "name" => name, "fact" => fact}}, socket) do
    :ok = GameServer.submit_fact(code, name, fact)

    {:noreply, redirect(socket, to: Routes.play_path(socket, :show, code, player: name))}
  end
end
