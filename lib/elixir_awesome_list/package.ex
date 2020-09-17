defmodule ElixirAwesomeList.Package do
  use Ecto.Schema
  import Ecto.Changeset

  schema "packages" do
    field :path, :string # "h4cc/awesome-elixir"
    field :link, :string # "https://github.com/h4cc/awesome-elixir"
    field :name, :string
    field :description, :string
    field :section, :string
    field :stars, :integer, default: 0

    field :last_commit_days, :integer, virtual: true, default: nil
    field :last_commit_date, :date

    field :status, :string, default: "new"
    field :hash, :string

    timestamps()
  end

  @package_statuses ["new", "processed", "unavailable"]
  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :path, :link, :stars, :status, :section, :hash, :last_commit_date])
    |> validate_required([:link, :section])
    |> validate_inclusion(:status, @package_statuses)
  end

  def update_changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :stars, :status, :description, :hash, :last_commit_date])
    |> validate_inclusion(:status, @package_statuses)
  end

  @doc """
  Subscribe to updates and new packages
  """
  @spec subscribe :: :ok | {:error, {:already_registered, pid}}
  def subscribe do
    Phoenix.PubSub.subscribe(ElixirAwesomeList.PubSub, "packages")
  end
end
