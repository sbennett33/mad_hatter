defmodule MadHatterWeb.PageController do
  use MadHatterWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
