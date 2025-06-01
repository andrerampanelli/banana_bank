defmodule BananaBank.Users.User do
  @moduledoc """
  User schema and changeset functions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true
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
    |> add_password_hash()
  end

  defp add_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Argon2.hash_pwd_salt(password))
  end

  defp add_password_hash(changeset), do: changeset
end

defimpl Jason.Encoder, for: BananaBank.Users.User do
  def encode(%BananaBank.Users.User{} = user, opts) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      address: user.address,
      balance: handle_balance(user.balance)
    }
    |> Jason.Encode.map(opts)
  end

  defp handle_balance(balance) when is_binary(balance) do
    case Float.parse(balance) do
      {value, _} -> round_balance(value)
      :error -> 0.00
    end
  end

  defp round_balance(balance) when is_float(balance) do
    Float.round(balance, 2)
  end
end
