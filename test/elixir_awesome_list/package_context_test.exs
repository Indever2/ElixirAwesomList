defmodule ElixirAwesomeList.Package.Context.Test do
  use ElixirAwesomeList.DataCase

  alias ElixirAwesomeList.Package

  describe "lib functions" do
    @valid_attrs %{:link => "https://github.com/h4cc/awesome-elixir", :section => "Test"}

    setup do
      Package.Search.reset_index()
      %{}
    end

    def package_fixture(attrs \\ %{}) do
      Enum.into(attrs, @valid_attrs)
      |> Package.Context.create_package()
    end

    test "[create_package] creates the package" do
      {:ok, package} = package_fixture()

      assert package.link == "https://github.com/h4cc/awesome-elixir"
      assert package.path == "h4cc/awesome-elixir"
      assert package.status == "new"
    end

    test "[update_package] updates the package" do
      {:ok, package} = package_fixture()

      assert package.link == "https://github.com/h4cc/awesome-elixir"
      assert package.path == "h4cc/awesome-elixir"
      assert package.status == "new"

      {:ok, updated_package} = Package.Context.update_package(package, %{:status => "processed", :paht => "i_cant_update_that"})

      assert updated_package.path == "h4cc/awesome-elixir"
      assert updated_package.status == "processed"

      {:error, %Ecto.Changeset{}} = Package.Context.update_package(package, %{:status => "some incorrect status"})
    end

    test "[list_packages] listing with parameters" do
      {:ok, _} = package_fixture()
      {:ok, _} = package_fixture(%{:status => "processed", :link => "https://github.com/h4cc/one"})
      {:ok, _} = package_fixture(%{:status => "processed", :link => "https://github.com/h4cc/two"})

      {:ok, packages} = Package.Context.list_packages(%{"status" => "processed"})

      assert length(packages) == 2

      # Min stars test
      for stars <- 1..10, do: package_fixture(%{:stars => stars, :link => "https://github.com/h4cc/#{stars}"})

      {:ok, packages} = Package.Context.list_packages(%{"min_stars" => 4})

      assert length(packages) == 7

      # Order by stars
      {:ok, packages} = Package.Context.list_packages(%{"min_stars" => 5, "orderby" => "stars"})

      assert Enum.map(packages, &(&1.stars)) == [10, 9, 8, 7, 6, 5]
    end

    test "[list_packages] orders by sections" do
      {:ok, _} = package_fixture(%{:section => "A"})
      {:ok, _} = package_fixture(%{:link => "https://github.com/h4cc/c", :section => "C"})
      {:ok, _} = package_fixture(%{:link => "https://github.com/h4cc/a", :section => "A"})
      {:ok, _} = package_fixture(%{:link => "https://github.com/h4cc/b", :section => "B", :status => "processed"})

      {:ok, packages} = Package.Context.list_packages()

      assert Enum.map(packages, &(&1.section)) == ["A", "A", "B", "C"]

      # With status filter
      {:ok, packages} = Package.Context.list_packages(%{"status" => "new"})

      assert Enum.map(packages, &(&1.section)) == ["A", "A", "C"]
    end

    test "[list_packages] searches by name, description, section and path" do
      {:ok, _} = package_fixture(%{:section => "Section one", :link => "https://github.com/first/path", :name => "1 first package"})
      {:ok, _} = package_fixture(%{:section => "Section one", :link => "https://github.com/second/pathy", :name => "2 another one"})
      {:ok, _} = package_fixture(%{:section => "Section Two", :link => "https://github.com/path/3", :name => "3 package from section two!"})

      # Search by section
      {:ok, packages} = Package.Context.list_packages(%{"query" => "Section", "orderby" => "name"})
      assert Enum.map(packages, &(&1.name)) == ["1 first package", "2 another one", "3 package from section two!"]

      {:ok, packages} = Package.Context.list_packages(%{"query" => "tw", "orderby" => "name"})
      assert Enum.map(packages, &(&1.name)) == ["3 package from section two!"]

      # Search by path
      {:ok, packages} = Package.Context.list_packages(%{"query" => "second/pathy", "orderby" => "name"})

      assert Enum.map(packages, &(&1.name)) == ["2 another one"]

      # Search by name
      {:ok, packages} = Package.Context.list_packages(%{"query" => "package", "orderby" => "name"})
      assert Enum.map(packages, &(&1.name)) == ["1 first package", "3 package from section two!"]
    end

    test "[list_packages] can return non-fresh packages" do
      today = Date.utc_today()

      {:ok, _} = package_fixture(%{:last_commit_date => today, :link => "https://github.com/path/1", :name => "1"})
      {:ok, _} = package_fixture(%{:last_commit_date => today, :link => "https://github.com/path/2", :name => "2"})
      {:ok, _} = package_fixture(%{:last_commit_date => ~D[1998-05-07], :link => "https://github.com/path/3", :name => "3"})

      # Search by section
      {:ok, packages} = Package.Context.list_packages(%{"last_commit_not_today" => true})
      assert Enum.map(packages, &(&1.name)) == ["3"]
    end
  end
end
