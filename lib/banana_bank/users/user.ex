defmodule BananaBank.Users.User do
  @moduledoc """
  User schema and changeset functions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @create_fields [:name, :email, :password, :address, :balance]
  @update_fields [:name, :email, :address, :balance]

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    # For precision, we use a string, and operations will be done with 5 decimal places
    field :balance, :string, default: "0.00000"
    field :address, :string

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

  defp handle_balance(nil), do: 0.00

  defp round_balance(balance) when is_float(balance) do
    Float.floor(balance * 100) / 100
  end
end
