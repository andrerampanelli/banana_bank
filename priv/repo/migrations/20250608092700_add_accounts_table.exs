defmodule BananaBank.Repo.Migrations.AddAccountsTable do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :balance, :decimal, scale: 5, default: fragment("0.00000")
      add :user_id, references(:users)

      timestamps()
    end

    create constraint(:accounts, :balance_must_be_positive, check: "balance >= 0")
  end

end
