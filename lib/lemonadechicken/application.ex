defmodule Lemonadechicken.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LemonadechickenWeb.Telemetry,
      Lemonadechicken.Repo,
      {DNSCluster, query: Application.get_env(:lemonadechicken, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lemonadechicken.PubSub},
      # Start a worker by calling: Lemonadechicken.Worker.start_link(arg)
      # {Lemonadechicken.Worker, arg},
      # Start to serve requests, typically the last entry
      LemonadechickenWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :lemonadechicken]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lemonadechicken.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LemonadechickenWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
