defmodule ElixirAwesomeList.Scrapper.PackageCommitInfoUpdater do
  @moduledoc """
  Updates last commit info for every package every tile ElixirAwesomeList.Scrapper.Creator checks for new packages.

  Initial parameters (keyword list): []
  """

  use GenServer
  require Logger

  alias ElixirAwesomeList.Scrapper
  alias ElixirAwesomeList.Package

  @impl true
  def init(arg) do
    Logger.info("[#{__MODULE__}] initializing...")

    ElixirAwesomeList.Scrapper.Creator.subscribe()

    {:ok, Enum.into(arg, %{})}
  end

  def start_link(arg) when is_list(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  defp schedule_work(interval) when is_integer(interval) do
    Process.send_after(self(), :last_commit_update, interval)
  end
  defp schedule_work(%{interval: interval}) when is_integer(interval) do
    Process.send_after(self(), :last_commit_update, interval)
  end

  @impl true
  def handle_info({ElixirAwesomeList.Scrapper.Creator, :job_done}, state) do
    Logger.info("[#{__MODULE__}] updating the commits info...")

    {:ok, packages} = Package.Context.list_packages(%{"last_commit_not_today" => true})
    for package <- packages do
      case Scrapper.Lib.get_repository_last_commit(package.path) do
        {:ok, commit} ->
          {:ok, last_commit_date_time} = Scrapper.Lib.commit_get_date(commit)
          last_commit_date = NaiveDateTime.to_date(last_commit_date_time)
          Package.Context.update_package(package,  %{ last_commit_date: last_commit_date })
        {:error, error} ->
          Logger.warn("[#{__MODULE__}] can't get last commit for package: #{package.link}")
          {:error, error}
      end
    end

    schedule_work(state)
    {:noreply, state}
  end
end
