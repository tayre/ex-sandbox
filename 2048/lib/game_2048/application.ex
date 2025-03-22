defmodule Game2048.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add restart strategy and increased timeouts
      {Phoenix.PubSub, name: Game2048.PubSub, pool_size: 1},
      # Registry for tracking player-specific game servers
      {Registry, keys: :unique, name: Game2048.GameRegistry},
      # Start the ScoreStore before GameServer with optimized settings
      {Game2048.ScoreStore, []},
      # Start the Game2048 GenServer with optimized settings
      {Game2048.GameServer, []},
      # Telemetry should start first
      Game2048Web.Telemetry,
      {DNSCluster, query: Application.get_env(:game_2048, :dns_cluster_query) || :ignore},
      # Start to serve requests, typically the last entry
      {Game2048Web.Endpoint, 
        # Add specific endpoint supervision options
        [shutdown: 10_000, restart: :permanent]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Game2048.Supervisor, max_restarts: 10]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Game2048Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
