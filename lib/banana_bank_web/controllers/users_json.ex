defmodule BananaBankWeb.UsersJSON do
  alias BananaBank.Users.User

  def create(%{user: user}) do
    %{
      message: "User created successfully",
      data: user
    }
  end

  def show(%{user: user}) do
    %{
      user: user
    }
  end
end
