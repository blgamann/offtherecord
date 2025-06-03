defmodule Offtherecord.Repo.Migrations.AssignAllPostsToMainUser do
  use Ecto.Migration

  def up do
    # Get the user ID for dn2757@gmail.com
    main_user_query = """
    SELECT id FROM users WHERE email = 'dn2757@gmail.com'
    """

    # Update all posts to belong to the main user
    execute """
    UPDATE posts 
    SET user_id = (#{main_user_query})
    WHERE user_id != (#{main_user_query})
    """
  end

  def down do
    # Cannot reverse this migration as we don't know the original user_ids
    # This is intentionally irreversible
    raise "Cannot reverse migration - original user ownership data would be lost"
  end
end
