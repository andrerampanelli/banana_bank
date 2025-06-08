defmodule BananaBank.Users.User do
  @moduledoc """
  User schema and changeset functions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias BananaBank.Accounts.Account

  @create_fields [:name, :email, :password, :address]
  @update_fields [:name, :email, :address]

  @derive {Jason.Encoder, only: [:id, :name, :email, :address, :inserted_at, :updated_at]}
  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :address, :string

    has_one :account, Account

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> validate_fields(attrs, @create_fields)
    |> add_password_hash()
  end

  def changeset(user, attrs) do
    user
    |> validate_fields(attrs, @update_fields)
  end

  defp validate_fields(changeset, attrs, fields) do
    changeset
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> validate_format(:email, ~r/.{3,}@.{3,}\..{2,3}/)
    |> validate_format(:name, ~r/^[A-ZÀ-Ýa-zà-ÿ\s'-]+$/)
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:email, min: 5, max: 100)
  end

  defp add_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Argon2.hash_pwd_salt(password))
  end

  defp add_password_hash(changeset), do: changeset
end
