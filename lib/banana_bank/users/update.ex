defmodule BananaBank.Users.Update do
  alias BananaBank.Repo
  alias BananaBank.Users.User

  def call(id, params) do
    try do
      case Repo.get(User, id) do
        nil ->
          {:error, :not_found}

        user ->
          update(user, params)
      end
    rescue
      Ecto.Query.CastError -> {:error, :not_found}
      ArgumentError -> {:error, :not_found}
    end
  end

  defp update(user, params) do
    user
    |> User.changeset(params)
    |> Repo.update()
  end
end
