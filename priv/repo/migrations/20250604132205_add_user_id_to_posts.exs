defmodule Offtherecord.Repo.Migrations.AddUserIdToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
    end

    create index(:posts, [:user_id])
  end
end
