defmodule MadHatter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      # Start the Telemetry supervisor
      MadHatterWeb.Telemetry,
      {Cluster.Supervisor, [topologies, [name: MadHatter.ClusterSupervisor]]},
      # Start the PubSub system
      {Phoenix.PubSub, name: MadHatter.PubSub},
      {Horde.Registry, [name: MadHatter.GameRegistry, keys: :unique, members: :auto]},
      {Horde.DynamicSupervisor,
       [
         name: MadHatter.DistributedSupervisor,
         shutdown: 1000,
         strategy: :one_for_one,
         members: :auto
       ]},
      # Start the Endpoint (http/https)
      MadHatterWeb.Endpoint
      # Start a worker by calling: MadHatter.Worker.start_link(arg)
      # {MadHatter.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MadHatter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MadHatterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
