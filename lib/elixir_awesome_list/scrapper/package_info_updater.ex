defmodule ElixirAwesomeList.Scrapper.PackageInfoUpdater do
  @moduledoc """
  Every time ElixirAwesomeList.Scrapper.Creator reports :job_done updating all packages that have changed.

  Every __last_commit_update_interval__ updating last commit info for every package.

  Initial parameters (keyword list): []
  """

  use GenServer
  require Logger

  alias ElixirAwesomeList.Scrapper
  alias ElixirAwesomeList.Package

  @impl true
  def init(arg) do
    Logger.info("[#{__MODULE__}] reindexing...")
    ElixirAwesomeList.Scrapper.Creator.subscribe()

    # ensure that after application restart all packages will be added to search index
    Package.Context.search_reindex_all()

    Logger.info("[#{__MODULE__}] initialized.")
    {:ok, Enum.into(arg, %{})}
  end

  def start_link(arg) when is_list(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def handle_info({ElixirAwesomeList.Scrapper.Creator, :job_done}, state) do
    Logger.info("[#{__MODULE__}] updating packages info...")
    update_existing_packages()

    Logger.info("[#{__MODULE__}] packages updated")
    {:noreply, state}
  end

  defp update_existing_packages do
    {:ok, packages} = Package.Context.list_packages()
    for package <- packages do
      case Scrapper.Lib.get_repository_info(package.path) do
        {:ok, repository_info} ->
          stars = repository_info["stargazers_count"]
          name = repository_info["name"]
          description = repository_info["description"]

          hash = :crypto.hash(:sha256, [to_string(stars), to_string(name), to_string(description)]) |> Base.encode16

          update_params = %{ stars: stars, name: name, description: description, status: "processed"}

          # update the package only if something inportant changed hash is not the same
          if hash != package.hash do
            Package.Context.update_package(package, update_params)
          else
            {:ok, :nothing_to_do}
          end

        {:error, error} ->
          Package.Context.update_package(package, %{"status" => "unavailable"})
          Logger.warn("[#{__MODULE__}] unavailable_package: #{package.link}")
          {:error, error}
      end
    end
  end
end
