defmodule BananaBankWeb.UsersJSON do
  alias BananaBank.Users.User

  def create(%{user: user}) do
    %{
      message: "User created successfully",
      data: data(user)
    }
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      address: user.address,
      balance: handle_balance(user.balance)
    }
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
