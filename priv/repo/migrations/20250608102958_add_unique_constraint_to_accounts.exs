defmodule BananaBank.Repo.Migrations.AddUniqueConstraintToAccounts do
  use Ecto.Migration

  def change do
    create unique_index(:accounts, [:user_id], name: :unique_account_user_id_index)
  end
end
