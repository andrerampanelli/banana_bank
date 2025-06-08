defmodule BananaBank.Accounts do
  @moduledoc """
  Context module for user operations.
  """

  alias BananaBank.Accounts.{Create}

  defdelegate create(params), to: Create, as: :call
end
