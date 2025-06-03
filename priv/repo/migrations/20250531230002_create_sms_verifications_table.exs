defmodule Offtherecord.Repo.Migrations.CreateSmsVerificationsTable do
  @moduledoc """
  Creates the sms_verifications table for SMS authentication.
  """

  use Ecto.Migration

  def up do
    create table(:sms_verifications, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v7()")
      add :phone_number, :string, null: false
      add :code, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :verified_at, :utc_datetime
      add :attempts, :integer, default: 0, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:sms_verifications, [:phone_number])
    create index(:sms_verifications, [:code])
    create index(:sms_verifications, [:expires_at])
  end

  def down do
    drop table(:sms_verifications)
  end
end
