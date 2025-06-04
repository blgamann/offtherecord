defmodule Offtherecord.Repo.Migrations.DropSmsVerificationsTable do
  @moduledoc """
  Drops the sms_verifications table as SMS authentication is being removed.
  """

  use Ecto.Migration

  def up do
    drop table(:sms_verifications)
  end

  def down do
    # Recreate the table if rollback is needed
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
end
