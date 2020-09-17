defmodule ElixirAwesomeList.Scrapper.Lib do
  import ElixirAwesomeList.PipelineContextProvider

  @doc """
  Dowonloads the file specified in __path__ parameter from GitHub repo and returns it as a string.

  Repo to download from must be passed in __repo__ parameter.
  * __repo__ argument format: Indever2/ElixirAwesomeList
  * __path__ argument format: lib/elixir_awesome_list/scrapper/lib.ex
  """
  def download_file_as_binary(repo, path) when is_binary(repo) and is_binary(path) do
    pipeline = [
      {&repo_contents_link/2, [path]},
      &get_authinticated/1,
      &extract_body/1,
      &Jason.decode/1,
      &download_url/1,
      &download_req/1,
      &extract_body/1
    ]
    unwrap pipeline(pipeline, repo)
  end

  @doc """
  Gets the repository info by accsessing the API with repository path.

  Repository path (the __repo__ argument) must look like "h4cc/awesome-elixir"
  """
  @spec get_repository_info(binary) :: {:error, any} | {:ok, map()}
  def get_repository_info(repo) when is_binary(repo) do
    pipeline = [
      &repo_info_link/1,
      &get_authinticated/1,
      &ensure_200/1,
      &extract_body/1,
      &Jason.decode/1
    ]

    unwrap pipeline(pipeline, repo)
  end

  @doc """
  Gets the repository commits by accsessing the API with repository/commits path.

  Repository path (the __repo__ argument) must look like "h4cc/awesome-elixir"
  """
  @spec get_repository_commits(binary) :: {:error, any} | {:ok, list()}
  def get_repository_commits(repo) when is_binary(repo) do
    pipeline = [
      &repo_commits_link/1,
      &get_authinticated/1,
      &ensure_200/1,
      &extract_body/1,
      &Jason.decode/1
    ]

    unwrap pipeline(pipeline, repo)
  end

  @doc """
  Gets the repository last commit by accsessing the API with repository/commits path
  and than getting the head of list.

  Repository path (the __repo__ argument) must look like "h4cc/awesome-elixir"
  """
  @spec get_repository_last_commit(binary) :: {:error, any} | {:ok, map()}
  def get_repository_last_commit(repo) when is_binary(repo) do
    case get_repository_commits(repo) do
      {:ok, [head | _]} -> {:ok, head}
      _ -> {:error, "Can't get the last commit"}
    end
  end

  @doc """
  Gets the commit date.

  __commit__ should be the map of json object that got from GitHub API
  """
  @spec commit_get_date(map) ::
          {:error, :incompatible_calendars | :invalid_date | :invalid_format | :invalid_time}
          | {:ok, NaiveDateTime.t()}
  def commit_get_date(commit) when is_map(commit) do
    NaiveDateTime.from_iso8601(commit["commit"]["committer"]["date"])
  end

  # Backstage functions

  defp get_authinticated(link) when is_binary(link) do
    config = Application.get_env(:elixir_awesome_list, ElixirAwesomeList.Scrapper, [])
    if not Keyword.has_key?(config, :git_hub_api_username) or not Keyword.has_key?(config, :git_hub_api_password) do
      {:error, "GitHub Auth are required. Specify the config params :git_hub_api_username and :git_hub_api_password for: :elixir_awesome_list, ElixirAwesomeList.Scrapper"}
    else
      hackney = [basic_auth: {Keyword.get(config, :git_hub_api_username), Keyword.get(config, :git_hub_api_password)}]
      HTTPoison.get(link, [], hackney: hackney)
    end
  end

  defp ensure_200(%HTTPoison.Response{status_code: status_code} = response) when status_code >= 200 and status_code < 300 do
    {:ok, response}
  end
  defp ensure_200(%HTTPoison.Response{status_code: status_code}), do: {:error, "Invalid status code: #{status_code}"}
  defp ensure_200(_), do: {:error, "Invalid response"}

  defp extract_body(%HTTPoison.Response{body: body}), do: {:ok, body}
  defp extract_body(_), do: {:error, "Can't get the response body"}

  defp download_url(%{"download_url" => url}), do: {:ok, url}
  defp download_url(_), do: {:error, "Can't get the download link"}

  defp download_req(link) when is_binary(link), do: HTTPoison.get(link)
  defp download_req(_), do: {:error, "Invalid link"}

  defp repo_info_link(repo) when is_binary(repo) do
    {:ok, Enum.reduce([api_root(), "repos", repo], "", fn part, acc -> Path.join(acc, part) end)}
  end
  defp repo_info_link(_repo), do: {:error, "Invalid repo"}
  defp repo_contents_link(repo, path) when is_binary(repo) and is_binary(path) do
    append_contents = fn repo_path ->
      {:ok, Enum.reduce(["contents", path], repo_path, fn part, acc -> Path.join(acc, part) end)}
    end

    unwrap pipeline([&repo_info_link/1, append_contents], repo)
  end
  defp repo_contents_link(_, _), do: {:error, "Invalid repo or file path"}
  defp repo_commits_link(repo) when is_binary(repo) do
    append_commits = fn repo_path ->
      {:ok, Path.join(repo_path, "commits")}
    end

    unwrap pipeline([&repo_info_link/1, append_commits], repo)
  end
  defp repo_commits_link(_), do: {:error, "Invalid repo path"}

  defp api_root do
    Application.get_env(:elixir_awesome_list, __MODULE__, [git_hub_api_root: "https://api.github.com/"])
    |> Keyword.get(:git_hub_api_root)
  end
end
