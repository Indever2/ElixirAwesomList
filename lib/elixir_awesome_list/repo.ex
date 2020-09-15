defmodule ElixirAwesomeList.Repo do
  use Ecto.Repo,
    otp_app: :elixir_awesome_list,
    adapter: Ecto.Adapters.Postgres
end
