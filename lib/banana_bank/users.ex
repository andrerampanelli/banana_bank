defmodule BananaBank.Users do
  @moduledoc """
  Context module for user operations.
  """

  alias BananaBank.Users.Create
  alias BananaBank.Users.Get

  defdelegate create_user(params), to: Create, as: :call
  defdelegate get_user(id), to: Get, as: :call
end
