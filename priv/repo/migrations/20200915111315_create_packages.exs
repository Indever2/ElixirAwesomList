defmodule ElixirAwesomeList.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def up do
    create table(:packages) do
      add :path, :string
      add :name, :string
      add :description, :text
      add :link, :text
      add :status, :string
      add :stars, :integer
      add :section, :string

      add :last_commit_date, :date

      add :hash, :string

      timestamps()
    end

    create unique_index(:packages, :path)
  end

  def donw do
    drop table(:packages)
  end
end
