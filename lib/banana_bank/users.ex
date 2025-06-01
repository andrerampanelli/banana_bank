defmodule BananaBank.Users do
  @moduledoc """
  Context module for user operations.
  """

  alias BananaBank.Users.{Create, Get, Update}

  defdelegate create(params), to: Create, as: :call
  defdelegate get(id), to: Get, as: :call
  defdelegate update(id, params), to: Update, as: :call
end
