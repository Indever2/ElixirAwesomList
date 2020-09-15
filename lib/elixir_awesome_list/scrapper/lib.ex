defmodule ElixirAwesomeList.Scrapper.Lib do
  import ElixirAwesomeList.PipelineContextProvider

  @doc """
  Dowonloads the file specified in __path__ parameter from GitHub repo and returns it as a string.

  Repo to download from must be passed in __repo__ parameter.
  * __repo__ argument format: Indever2/ElixirAwesomeList
  * __path__ argument format: lib/elixir_awesome_list/scrapper/lib.ex
  """
  def download_file_as_binary(repo, path) when is_binary(repo) and is_binary(path) do
    # dbg_f = fn obj -> {:ok, IO.inspect obj} end

    pipeline = [
      {&format_link/2, [path]},
      &HTTPoison.get/1,
      &extract_body/1,
      &Jason.decode/1,
      &download_url/1,
      &download_req/1,
      &extract_body/1
    ]
    unwrap pipeline(pipeline, repo)
  end

  defp extract_body(%HTTPoison.Response{body: body}), do: {:ok, body}
  defp extract_body(_), do: {:error, "Can't get the response body"}

  defp download_url(%{"download_url" => url}), do: {:ok, url}
  defp download_url(_), do: {:error, "Can't get the download link"}

  defp download_req(link) when is_binary(link), do: HTTPoison.get(link)
  defp download_req(_), do: {:error, "Invalid link"}

  defp format_link(repo, path) when is_binary(repo) and is_binary(path) do
    api_root =
      Application.get_env(:elixir_awesome_list, __MODULE__, [git_hub_api_root: "https://api.github.com/"])
      |> Keyword.get(:git_hub_api_root)

    {:ok, Enum.reduce([api_root, "repos", repo, "contents", path], "", fn part, acc -> Path.join(acc, part) end)}
  end
  defp format_link(_, _), do: {:error, "Invalid repo or file path"}
end
