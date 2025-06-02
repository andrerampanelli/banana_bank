defmodule BananaBank.Users.Delete do
  alias BananaBank.Repo
  alias BananaBank.Users.User

  def call(id) do
    try do
      case Repo.get(User, id) do
        nil -> {:error, :not_found}
        user -> Repo.delete(user)
      end
    rescue
      Ecto.Query.CastError -> {:error, :not_found}
      ArgumentError -> {:error, :not_found}
    end
  end
end
