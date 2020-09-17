defmodule ElixirAwesomeListWeb.PageLive.ItemComponent do
  use ElixirAwesomeListWeb, :live_component

  alias ElixirAwesomeList.Package

  def render(assigns) do
    ~L"""
    <%= render_item(assigns, assigns.item) %>
    """
  end

  defp render_item(assigns, {section, [%Package{}|_] = packages}) when is_binary(section) and is_list(packages) do
    ~L"""
    <h3><%= section %></h3>
    <ul class="nested-list">
    <%= for package <- packages do %>
      <li><%= render_item(assigns, package) %></li>
    <% end %>
    </ul>
    """
  end
  defp render_item(%{} = assigns, %Package{name: name, link: link} = package) do
    ~L"""
    <div class="package-item
      <%= if newly_updated?(package) do %>
      newly-updated
      <% end %>
      "
    >
      <a href="<%= link %>" target="_blank">
        <span class="item-name"><%= name %></span>
      </a>
      <span class="item-stars">&#11088;<%= package.stars %></span>
      <span class="item-calendar">&#128197;<%= package.last_commit_days %></span>
      <span class="item-description"> <%= package.description %></span>
    </div>
    """
  end

  defp newly_updated?(%Package{updated_at: updated_at}) do
    NaiveDateTime.diff(NaiveDateTime.utc_now, updated_at) < 10
  end
end
