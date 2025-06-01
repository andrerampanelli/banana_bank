defmodule BananaBank.Users do
  @moduledoc """
  Context module for user operations.
  """

  alias BananaBank.Users.Create

  defdelegate create_user(params), to: Create, as: :call
end
