defmodule ElixirAwesomeList.Package do
  use Ecto.Schema
  import Ecto.Changeset

  schema "packages" do
    field :link, :string
    field :name, :string
    field :stars, :integer

    timestamps()
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :link, :stars])
    |> validate_required([:name, :link, :stars])
  end
end
