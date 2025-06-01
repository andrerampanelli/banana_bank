defmodule BananaBank.Users.Get do
  alias BananaBank.Repo
  alias BananaBank.Users.User

  def call(id) do
    case Repo.get(User, id) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end
end
