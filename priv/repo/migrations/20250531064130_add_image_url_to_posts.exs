defmodule Offtherecord.Repo.Migrations.AddImageUrlToPosts do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:posts) do
      add :image_url, :text
    end
  end

  def down do
    alter table(:posts) do
      remove :image_url
    end
  end
end
