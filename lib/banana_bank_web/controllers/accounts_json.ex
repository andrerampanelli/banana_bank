defmodule BananaBankWeb.AccountsJSON do

  def create(%{account: account}) do
    %{
      message: "Account created successfully",
      data: account
    }
  end
end
