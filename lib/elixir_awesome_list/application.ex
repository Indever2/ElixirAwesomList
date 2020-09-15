defmodule ElixirAwesomeList.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ElixirAwesomeList.Repo,
      # Start the Telemetry supervisor
      ElixirAwesomeListWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ElixirAwesomeList.PubSub},
      # Start the Endpoint (http/https)
      ElixirAwesomeListWeb.Endpoint,
      # Start the GitHub Scrapper
      {ElixirAwesomeList.Scrapper, Keyword.new()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirAwesomeList.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElixirAwesomeListWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
