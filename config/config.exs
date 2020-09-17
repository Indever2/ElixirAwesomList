# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :elixir_awesome_list,
  ecto_repos: [ElixirAwesomeList.Repo]

# Configures the endpoint
config :elixir_awesome_list, ElixirAwesomeListWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "G2cWAZdAcOq2mBVfr3y3i3KSTYrygLocItuARoOg2fa7ZNvhgs4SIF9/Cl+hf5by",
  render_errors: [view: ElixirAwesomeListWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ElixirAwesomeList.PubSub,
  live_view: [signing_salt: "0h9RZCFj"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Scrapper config
config :elixir_awesome_list, ElixirAwesomeList.Scrapper,
  git_hub_api_root: "https://api.github.com/"#,
  #git_hub_api_username: "Username",
  #git_hub_api_password: "Password"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
