defmodule ElixirAwesomeListWeb.PageLive do
  use ElixirAwesomeListWeb, :live_view

  alias ElixirAwesomeList.Package
  alias ElixirAwesomeListWeb.PackageView

  import ElixirAwesomeList.PipelineContextProvider

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket), do: Package.subscribe()

    {:ok, params} = process_params(params)

    socket = assign(socket, ignore_sections?: false, orderby: "name", min_stars: params["min_stars"], query: "", items: [])

    Task.async(fn -> list_packages_async(socket.assigns) end)
    {:ok, socket}
  end

  @impl true
  def handle_event("ignore_sections_click", %{}, socket) do
    ignore_sections? = not socket.assigns.ignore_sections?
    socket = assign(socket, :ignore_sections?, ignore_sections?)

    Task.async(fn -> list_packages_async(socket.assigns) end)

    {:noreply, socket}
  end

  def handle_event("order_changed", %{"orderby" => new_orderby}, socket) do
    socket = assign(socket, :orderby, new_orderby)

    Task.async(fn -> list_packages_async(socket.assigns) end)

    {:noreply, socket}
  end

  def handle_event("min_stars_input", %{"min_stars" => min_stars}, socket) when is_binary(min_stars) do
    new_min_stars =
      case Integer.parse(min_stars, 10) do
        {num, _} -> num
        :error -> 0
      end

    socket = assign(socket, :min_stars, new_min_stars)

    Task.async(fn -> list_packages_async(socket.assigns) end)
    {:noreply, socket}
  end

  def handle_event("search_input", %{"q" => query}, socket) do
    socket = assign(socket, :query, query)
    Task.async(fn -> list_packages_async(socket.assigns) end)

    {:noreply, socket}
  end


  @impl true
  def handle_info({:package_created, %Package{}}, socket) do
    Task.async(fn -> list_packages_async(socket.assigns) end)

    {:noreply, socket}
  end
  def handle_info({:package_updated, %Package{}}, socket) do
    Task.async(fn -> list_packages_async(socket.assigns) end)

    {:noreply, socket}
  end

  # Items update processing
  def handle_info({_ref, {:items_updated, items}}, socket) do
    {:noreply, assign(socket, items: items)}
  end
  def handle_info({:DOWN, _ref, :process, _pid, _}, socket) do
    {:noreply, socket}
  end

  defp process_params(params) do
    unwrap pipeline([&process_min_stars/1], params)
  end

  defp process_min_stars(%{"min_stars" => ms} = params) when is_binary(ms) do
    case Integer.parse(ms, 10) do
      {number, _} -> {:ok, Map.put(params, "min_stars", number)}
      _ -> {:ok, Map.put(params, "min_stars", 0)}
    end
  end
  defp process_min_stars(%{} = params), do: {:ok, Map.put(params, "min_stars", 0)}


  defp list_packages_async(assigns) do
    min_stars = assigns.min_stars
    ignore_sections? = assigns.ignore_sections?
    orderby = assigns.orderby
    query = assigns.query

    list_params = %{
      "query" => query,
      "min_stars" => min_stars,
      "status" => "processed",
      "orderby" => orderby,
      "ignore_sections" => ignore_sections?,
    }

    {:ok, items} = Package.Context.list_packages(list_params)

    {:ok, items} = PackageView.view(items, group_by_sections: not ignore_sections?)

    {:items_updated, items}
  end
end
