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
  end
end
