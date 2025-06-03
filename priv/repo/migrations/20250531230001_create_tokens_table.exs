defmodule Offtherecord.Repo.Migrations.CreateTokensTable do
  @moduledoc """
  Creates the tokens table for authentication.
  """

  use Ecto.Migration

  def up do
    create table(:tokens, primary_key: false) do
      add :jti, :text, primary_key: true
      add :subject, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :purpose, :text, null: false
      add :extra_data, :map

      timestamps(type: :utc_datetime_usec)
    end

    create index(:tokens, [:subject])
    create index(:tokens, [:expires_at])
  end

  def down do
    drop table(:tokens)
  end
end
