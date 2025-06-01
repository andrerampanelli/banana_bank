defmodule BananaBankWeb.UsersJSON do
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

  def update(%{user: user}) do
    %{
      message: "User updated successfully",
      user: user
    }
  end
end
