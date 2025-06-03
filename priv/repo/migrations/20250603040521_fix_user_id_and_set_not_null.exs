defmodule Offtherecord.Repo.Migrations.FixUserIdAndSetNotNull do
  use Ecto.Migration

  def up do
    # First, update all NULL user_ids to the main user
    execute """
    UPDATE posts 
    SET user_id = (SELECT id FROM users WHERE email = 'dn2757@gmail.com' LIMIT 1)
    WHERE user_id IS NULL
    """

    # Then set the column to NOT NULL
    alter table(:posts) do
      modify :user_id, :uuid, null: false
    end
  end

  def down do
    alter table(:posts) do
      modify :user_id, :uuid, null: true
    end
  end
end
