defmodule ElixirAwesomeList.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string
      add :link, :text
      add :stars, :integer

      timestamps()
    end

  end
end
