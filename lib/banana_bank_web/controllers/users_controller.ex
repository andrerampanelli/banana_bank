defmodule BananaBankWeb.UsersController do
  use BananaBankWeb, :controller

  alias BananaBank.Users
  alias BananaBank.Users.User

  action_fallback BananaBankWeb.FallbackController

  def create(conn, params) do
    with {:ok, %User{} = user} <- Users.create_user(params) do
      conn
      |> put_status(:created)
      |> render(:create, user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, %User{} = user} <- Users.get_user(id) do
      conn
      |> put_status(:ok)
      |> render(:show, user: user)
    end
  end
end
