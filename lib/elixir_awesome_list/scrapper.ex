defmodule ElixirAwesomeList.Scrapper do
  use Supervisor
  require Logger

  import ElixirAwesomeList.PipelineContextProvider

  @impl true
  def init(_attrs) do
    children = [
      {ElixirAwesomeList.Scrapper.Creator, [interval: 1000 * 60 * 60 * 24]}, # Checking for the new packages every hour
      {ElixirAwesomeList.Scrapper.PackageInfoUpdater, []}, # Will be executed when Creator finish its task
      {ElixirAwesomeList.Scrapper.PackageCommitInfoUpdater, []} # Will be executed when Creator finish its task
    ]

    Supervisor.init(children, strategy: :one_for_one, name: ScrapperSupervisor)
  end
  def start_link(init_arg) do
    Logger.info("[#{__MODULE__}]: start link!")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Parses markdown file and extracts all packages.
  """
  @spec parse_list_file(binary) :: {:error, any} | {:ok, list(map)}
  def parse_list_file(content) when is_binary(content) do
    pipeline = [
      &md_split_by_h1/1,
      &head/1, # We don't need Contributing and Resources sections
      &md_split_by_h2/1,
      &tail/1,
      # After that step we have a list of sections and every section look like
      # "Actors\n
      # *Libraries and tools for working with actors and such.*\n\n
      # * [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.\n* ... "
      &process_sections/1
    ]

    unwrap pipeline(pipeline, content)
  end

  defp md_split_by_h1(md_file) when is_binary(md_file) do
    {:ok, Regex.split(~r/\n\#{1} | ^\#{1} /, md_file)}
  end
  defp md_split_by_h1(_), do: {:error, "Invalid argument"}

  defp md_split_by_h2(md_file) when is_binary(md_file) do
    {:ok, Regex.split(~r/\n\#{2} | ^\n\#{2} /, md_file)}
  end
  defp md_split_by_h2(_), do: {:error, "Invalid argument"}

  defp head([head|_]), do: {:ok, head}
  defp head(_), do: {:ok, "Can't get the head of list"}

  defp tail([_|tail]), do: {:ok, tail}
  defp tail(_), do: {:ok, "Can't get the tail of list"}

  defp process_sections(sections) when is_list(sections) and sections != [] do
    pipeline = for section <- sections, do: {&process_single_section/2, [String.trim(section)]}

    unwrap pipeline(pipeline, [])
  end
  defp process_sections(_), do: {:error, "Invalid sections"}

  defp process_single_section(accumulator, "") when is_list(accumulator), do: {:ok, accumulator}
  defp process_single_section(accumulator, section) when is_list(accumulator) and is_binary(section) do

    extract_name_f =
      fn %{} = acc ->
        case Regex.scan(~r/^[[:word:]].*/, section) do
          [[name]] when is_binary(name) ->
            {:ok, Map.put(acc, :name, name)}
          _ -> {:error, "Invalid name"}
        end
    end

    extract_packages_f =
      fn
        %{} = acc ->
          case Regex.scan(~r/\[.*\]\(https:\/\/github\.com\/[A-Za-z0-9\-._']+\/[A-Za-z0-9\-._']+\)/, section) do
            [ [first_package]| _] = packages when is_binary(first_package) ->
              extract_f =
                fn [x] ->
                  [value] = Regex.run(~r/https:\/\/github\.com\/[A-Za-z0-9\-._']+\/[A-Za-z0-9\-._']+/, x)
                  value
                end

              packages = Enum.map(packages, extract_f)
              {:ok, Map.put(acc, :packages, packages)}

            _ ->
              {:error, "Invalid packages"}
          end
        end

    case unwrap pipeline([extract_name_f, extract_packages_f], %{}) do
      {:ok, %{} = section} -> {:ok, accumulator ++ [section]}
      {:error, _parse_section_error} -> {:ok, accumulator}
    end

  end
  defp process_single_section(_, _), do: {:error, "Section parse error"}
end
