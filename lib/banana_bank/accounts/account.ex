defmodule BananaBank.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias Decimal

  alias BananaBank.Users.User

  @required_fields [:balance, :user_id]

  schema "accounts" do
    field :balance, :decimal, default: Decimal.new("0.00000")
    belongs_to :user, User

    timestamps()
  end

  def changeset(account \\ %__MODULE__{}, attrs) do
    account
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> check_constraint(:balance, name: :balance_must_be_positive, message: "insufficient funds")
    |> unique_constraint(:user_id, name: :unique_account_user_id_index)
  end
end

defimpl Jason.Encoder, for: BananaBank.Accounts.Account do
  def encode(%BananaBank.Accounts.Account{} = account, opts) do
    %{
      id: account.id,
      balance: handle_balance(account.balance)
    }
    |> Jason.Encode.map(opts)
  end

  defp handle_balance(%Decimal{} = balance) do
    Decimal.round(balance, 2)
  end

  defp handle_balance(nil), do: "0.00"
end
