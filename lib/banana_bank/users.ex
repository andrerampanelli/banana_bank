defmodule BananaBank.Users do
  @moduledoc """
  Context module for user operations.
  """

  alias BananaBank.Users.{Create, Get, Update, Delete}

  defdelegate create(params), to: Create, as: :call
  defdelegate get(id), to: Get, as: :call
  defdelegate update(id, params), to: Update, as: :call
  defdelegate delete(id), to: Delete, as: :call
end
