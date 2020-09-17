defmodule ElixirAwesomeListWeb.PackageView do
  alias ElixirAwesomeList.Package

  import ElixirAwesomeList.PipelineContextProvider

  @doc """
  Represent given package (or packages) using the __params__ passed.

  Supported __params__ options:
  * group_by_sections - if `true` returns list of packages as list of sections with their packages.
  """
  def view(package_or_packages, params \\ Keyword.new())
  def view([], _), do: {:ok, []}
  def view([%Package{}| _] = packages, params) do
    params = Enum.into(params, %{})

    unwrap pipeline([&apply_view/1, {&group_by_sections/2, [params]}], packages)
  end
  def view(%Package{} = package, _params) do
    pipeline = [&put_last_commit_days/1]
    unwrap pipeline(pipeline, package)
  end

  def apply_view([%Package{}|_] = packages) do
    view_f = fn acc, %Package{} = package ->
      case view(package) do
        {:ok, package} -> {:ok, acc ++ [package]}
        {:error, error} -> {:error, error}
      end
    end

    pipeline = for package <- packages, do: {view_f, [package]}
    unwrap pipeline(pipeline, [])
  end

  defp group_by_sections([], _), do: {:ok, []}
  defp group_by_sections([%Package{}|_] = packages, %{group_by_sections: true}) do
    reduce_f =
      fn %Package{section: section} = package, %{} = acc ->
        Map.update(acc, section, [package], fn list -> list ++ [package] end)
      end

    list =
      Enum.reduce(packages, %{}, reduce_f)
      |> Map.to_list()
      |> Enum.sort(fn {one, _}, {two, _} -> two >= one end)

    {:ok, list}
  end
  defp group_by_sections([%Package{}|_] = packages, %{}), do: {:ok, packages}
  defp group_by_sections(_, _), do: {:error, "Invalid argument"}

  defp put_last_commit_days(%Package{last_commit_date: lc_date} = package) do
    today = Date.utc_today()
    days = case lc_date do
      nil -> nil
      _ -> Date.diff(today, lc_date)
    end
    {:ok, %Package{package| last_commit_days: days}}
  end
end
