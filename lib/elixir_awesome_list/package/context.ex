defmodule ElixirAwesomeList.Package.Context do
  alias ElixirAwesomeList.Repo

  alias ElixirAwesomeList.Package

  import Ecto.Query
  import ElixirAwesomeList.PipelineContextProvider

  @doc """
  Creates a package with a given attrs.
  """
  @spec create_package(map) :: {:error, any} | {:ok, Package.t()}
  def create_package(%{} = attrs) do
    pp = [
      {&create_changeset/2, [attrs]},
      &process_path/1,
      &Repo.insert/1,
      {&broadcast/2, [:package_created]},
      &add_to_index/1
    ]

    unwrap pipeline(pp, %Package{})
  end

  @doc """
  Updates the package with a given attrs
  """
  @spec update_package(ElixirAwesomeList.Package.t(), map) :: {:error, any} | {:ok, Package.t()}
  def update_package(%Package{} = package, %{} = attrs) do
    pp = [
      {&update_changeset/2, [attrs]},
      &Repo.update/1,
      {&broadcast/2, [:package_updated]},
      &update_index/1
    ]

    unwrap pipeline(pp, package)
  end

  @doc """
  Returns a list of packages according to given params (map).

  Supported options:
  * "status" ("new" | "processed" | "unavailable") - filter by status
  * "min_stars" (integer) - select only packages with "stars" field more than "min_stars"
  * "ignore_section" - group the result by sections if value is true
  * "orderby" - ("name"|"stars") no comments
  * "query" - (string) if value is not an empty string, filters the result with given query
  """
  @spec list_packages(map()) :: {:error, any} | {:ok, list(Package.t())}
  def list_packages(params \\ %{}) do
    repo_all = fn query -> {:ok, Repo.all(query)} end

    pipeline = [
      {&sort_by_section/2, [params]},
      {&sort_by_name/2, [params]},
      {&sort_by_stars/2, [params]},
      {&status_filter/2, [params]},
      {&stars_filter/2, [params]},
      {&process_search/2, [params]},
      {&last_commit_not_today/2, [params]},
      repo_all
    ]

    unwrap pipeline(pipeline, from(p in Package))
  end

  @doc """
  Gets the package by link. Returns `nil` if there's no such package
  """
  @spec get_by_link(binary) :: nil | Package.t()
  def get_by_link(link) when is_binary(link) do
    Repo.get_by(Package, link: link)
  end

  @doc """
  Drops the search index and renews it with all of packages
  """
  @spec search_reindex_all :: :ok
  def search_reindex_all do
    Package.Search.reset_index()

    {:ok, all_packages} = list_packages()
    Enum.each(all_packages, &add_to_index/1)
  end


  # Backstage functions

  defp create_changeset(%Package{} = package, %{} = attrs), do: {:ok, Package.changeset(package, attrs)}
  defp create_changeset(_, _), do: {:error, "[create_changes] invalid params"}

  defp update_changeset(%Package{} = package, %{} = attrs), do: {:ok, Package.update_changeset(package, attrs)}
  defp update_changeset(_, _), do: {:error, "[update_changeset] invalid params"}

  defp process_path(%Ecto.Changeset{changes: %{link: link}} = changeset) do
    path = Regex.replace(~r/https:\/\/github.com\//, link, "")
    {:ok, Ecto.Changeset.put_change(changeset, :path, path)}
  end
  defp process_path(%Ecto.Changeset{} = changeset), do: {:ok, changeset}


  # List functions

  defp status_filter(query, %{"status" => status}) do
    {:ok, where(query, [p], p.status == ^status)}
  end
  defp status_filter(query, %{}), do: {:ok, query}

  defp stars_filter(query, %{"min_stars" => min_stars}) do
    {:ok, where(query, [p], p.stars >= ^min_stars)}
  end
  defp stars_filter(query, %{}), do: {:ok, query}

  defp sort_by_section(query, %{"ignore_sections" => true}), do: {:ok, query}
  defp sort_by_section(query, %{}), do: {:ok, order_by(query, [asc: :section])}

  defp sort_by_name(query, %{"orderby" => "name"}) do
    {:ok, order_by(query, [{:asc, :name}])}
  end
  defp sort_by_name(query, %{}), do: {:ok, query}

  defp sort_by_stars(query, %{"orderby" => "stars"}) do
    {:ok, order_by(query, [{:desc, :stars}])}
  end
  defp sort_by_stars(query, %{}), do: {:ok, query}

  defp last_commit_not_today(query, %{"last_commit_not_today" => true}) do
    {:ok, datetime} = NaiveDateTime.new(Date.utc_today(), ~T[00:00:00])
    {:ok, where(query, [p], is_nil(p.last_commit_date) or p.last_commit_date < ^datetime)}
  end
  defp last_commit_not_today(query, %{}), do: {:ok, query}

  defp process_search(query, %{"query" => ""}), do: {:ok, query}
  defp process_search(query, %{"query" => q}) when is_binary(q) do
    result = Package.Search.search(q)
    matches_ids = Enum.map(result.matches, &(&1.id))

    {:ok, where(query, [p], p.id in ^matches_ids)}
  end

  defp process_search(query, %{}), do: {:ok, query}


  # Search functions

  defp add_to_index(%Package{} = package) do
    Package.Search.update_index(package)
    {:ok, package}
  end
  defp update_index(%Package{} = package) do
    Package.Search.update_index(package)
    {:ok, package}
  end


  # Process interaction and notifications

  defp broadcast(%Package{} = package, message) do
    case Phoenix.PubSub.broadcast(ElixirAwesomeList.PubSub, "packages", {message, package}) do
      :ok -> {:ok, package}
      {:error, error} -> {:error, error}
    end
  end
end
