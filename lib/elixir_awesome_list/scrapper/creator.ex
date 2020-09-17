defmodule ElixirAwesomeList.Scrapper.Creator do
  @moduledoc """
  Every hour checks for new packages from GitHub repository `h4cc/awesome-elixir`.

  If package exists in the repo but not exists in app database than it will be created.

  Initial parameters (keyword list):
  * interval: integet() - looking for new packages interval
  """
  use GenServer
  require Logger

  alias ElixirAwesomeList.Scrapper
  alias ElixirAwesomeList.Package


  @doc """
  Subscribe to jobs
  """
  @spec subscribe :: :ok | {:error, {:already_registered, pid}}
  def subscribe do
    Phoenix.PubSub.subscribe(ElixirAwesomeList.PubSub, "#{__MODULE__}")
  end

  @impl true
  def init(arg) do
    Logger.info("[#{__MODULE__}] initializing...")
    schedule_work(10_000)
    {:ok, Enum.into(arg, %{})}
  end

  def start_link(arg) when is_list(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def handle_info(:lookup_for_new_packages, state) do
    Logger.info("[#{__MODULE__}] looking up for new packages...")
    :ok = look_for_new_packages()

    schedule_work(state)
    broadcast_done()

    Logger.info("[#{__MODULE__}] Packages renewed")
    {:noreply, state}
  end

  defp schedule_work(interval) when is_integer(interval) do
    Process.send_after(self(), :lookup_for_new_packages, interval)
  end
  defp schedule_work(%{interval: interval}) when is_integer(interval) do
    Process.send_after(self(), :lookup_for_new_packages, interval)
  end

  defp look_for_new_packages do
    {:ok, binary} = Scrapper.Lib.download_file_as_binary("h4cc/awesome-elixir", "README.md")
    {:ok, sections} = Scrapper.parse_list_file(binary)

    Enum.each(sections, fn section ->
      for package <- section.packages do
        if Package.Context.get_by_link(package) == nil do # if there are no package with that link
          Package.Context.create_package(%{link: package, section: section.name})
        end
      end
    end)
  end

  defp broadcast_done do
    Phoenix.PubSub.broadcast(ElixirAwesomeList.PubSub, "#{__MODULE__}", {__MODULE__, :job_done})
  end
end
