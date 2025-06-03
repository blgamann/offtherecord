defmodule Offtherecord.Repo.Migrations.CreateUsersTable do
  @moduledoc """
  Creates the users table for authentication.
  """

  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS citext")

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v7()")
      add :email, :citext
      add :phone_number, :string
      add :name, :string
      add :picture, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:phone_number])
  end

  def down do
    drop table(:users)
    execute("DROP EXTENSION IF EXISTS citext")
  end
end
