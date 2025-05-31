defmodule Offtherecord.Record.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Offtherecord.Record,
    extensions: [AshJsonApi.Resource]

  json_api do
    type "post"
  end

  postgres do
    table "posts"
    repo Offtherecord.Repo
  end

  actions do
    default_accept [:content, :date]
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string do
      allow_nil? false
      public? true
    end

    attribute :date, :date do
      allow_nil? false
      public? true
      default &Date.utc_today/0
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
