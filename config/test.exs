import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mad_hatter, MadHatterWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "8gMl10Cnwq3ibgeeDyy8wnlzuZQpq4uTcmmCEqZ6QP5b/NuSNCxaBd93DoCe/3mj",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :libcluster,
  topologies: [
    gossip: [
      strategy: Elixir.Cluster.Strategy.Gossip
    ]
  ]
