defmodule BananaBank.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :password_hash, :string
    field :balance, :string, default: "000"
    field :address, :string

    timestamps()
  end

  def changeset(user \\ %__MODULE__{}, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :balance, :address])
    |> validate_required([:name, :email, :password, :address])
    |> validate_format(:email, ~r/.{3,}@.{3,}\..{2,3}/)
    |> validate_format(:name, ~r/^[A-ZÀ-Ýa-zà-ÿ\s]+$/)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:email, min: 5, max: 100)
  end
end
