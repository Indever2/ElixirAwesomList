defmodule ElixirAwesomeList.Package.Search do
  alias ElixirAwesomeList.Package

  @index_name :package_index

  defp create_index_if_not_exists do
    Ftelixir.create_index(@index_name, %{autocomplete: true})
  end

  defp search_string(%Package{name: name, description: description, section: section, path: path}) do
    nil_to_empty =
      fn nil -> ""
        obj -> obj
      end

    [name, description, section, path]
    |> Enum.map(nil_to_empty)
    |> Enum.join(" ")
    |> String.trim()
  end

  def search(search_query) when is_binary(search_query) do
    apply_action_wrapper(:search, search_query)
  end
  def add_to_index(%Package{} = package) do
    apply_action_wrapper(:add_to_index, package)
  end
  def update_index(%Package{} = package) do
    apply_action_wrapper(:update_index, package)
  end
  def delete_from_index(%Package{} = package) do
    apply_action_wrapper(:delete_from_index, package)
  end
  def reset_index do
    apply_action_wrapper(:reset_index, [])
  end



  def apply_action_wrapper(action, args) do
    create_index_if_not_exists()
    apply_action(action, args)
  end

  defp apply_action(:search, query) do
    Ftelixir.search(query, nil, [max: :all], @index_name)
  end
  defp apply_action(:add_to_index, %Package{id: id} = package) do
    Ftelixir.add_to_index(id, search_string(package), %{}, @index_name)
  end
  defp apply_action(:update_index, %Package{id: id} = package) do
    Ftelixir.delete_key_from_index(@index_name, id)
    Ftelixir.add_to_index(id, search_string(package), %{}, @index_name)
  end
  defp apply_action(:delete_from_index, %Package{id: id}) do
    Ftelixir.delete_key_from_index(@index_name, id)
  end
  defp apply_action(:reset_index, _) do
    Ftelixir.drop_tables(@index_name)
  end
end
