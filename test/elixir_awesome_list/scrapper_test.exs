defmodule ElixirAwesomeList.Scrapper.Test do
  alias ElixirAwesomeList.Scrapper
  use ElixirAwesomeList.DataCase

  describe "lib functions" do
    test "[download_file_as_binary] can get needed file" do
      {:ok, binary} = Scrapper.Lib.download_file_as_binary("h4cc/awesome-elixir", "README.md")

      assert is_binary(binary)
    end

    test "[parse_list_file] parsing correct" do
      {:ok, binary} = Scrapper.Lib.download_file_as_binary("h4cc/awesome-elixir", "README.md")

      assert is_binary(binary)

      {:ok, sections} = Scrapper.parse_list_file(binary)

      for section <- sections do
        assert is_binary(section.name)
        assert section.name != ""

        assert section.packages != []
      end
    end

    test "[get_repository_info] returns info object" do
      {:ok, repository_info} = Scrapper.Lib.get_repository_info("h4cc/awesome-elixir")

      assert repository_info["full_name"] == "h4cc/awesome-elixir"
      assert repository_info["owner"]["login"] == "h4cc"
      assert repository_info["created_at"] == "2014-07-01T21:12:03Z"
    end

    test "[get_repository_last_commit] returns the last repository commit" do
      {:ok, commits} = Scrapper.Lib.get_repository_commits("h4cc/awesome-elixir")

      max_commits_date_f =
        fn
          commit, :first -> # if first - set accumulator to first commit date
            {:ok, date} = Scrapper.Lib.commit_get_date(commit)
            {date, commit}
          commit, {acc_date, _} = acc -> # otherwise compare accumulator date to every commit date
            {:ok, date} = Scrapper.Lib.commit_get_date(commit)
              case NaiveDateTime.compare(acc_date, date) do
                :lt -> {date, commit} # and renew accumulator if needed
                _ -> acc
              end
        end

      {_, last_commit_checked} = Enum.reduce(commits, :first, max_commits_date_f)

      # checking that last commit from get_repository_last_commit accords to last commit got manually
      {:ok, last_commit} = Scrapper.Lib.get_repository_last_commit("h4cc/awesome-elixir")
      assert last_commit == last_commit_checked
    end
  end
end
