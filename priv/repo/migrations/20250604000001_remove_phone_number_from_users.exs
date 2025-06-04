defmodule Offtherecord.Repo.Migrations.RemovePhoneNumberFromUsers do
  @moduledoc """
  Removes phone_number column from users table as SMS authentication is being removed.
  """

  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :phone_number
    end

    # Also drop the unique index on phone_number
    drop_if_exists unique_index(:users, [:phone_number])
  end

  def down do
    alter table(:users) do
      add :phone_number, :string
    end

    create unique_index(:users, [:phone_number])
  end
end
