defmodule Offtherecord.Record.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Offtherecord.Record,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource]

  postgres do
    table "posts"
    repo Offtherecord.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string do
      allow_nil? false
      public? true
    end

    attribute :date, :utc_datetime do
      allow_nil? false
      public? true
      default &DateTime.utc_now/0
    end

    attribute :image_url, :string do
      allow_nil? true
      public? true
    end

    attribute :user_id, :uuid do
      allow_nil? true
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Offtherecord.Accounts.User do
      allow_nil? true
      public? true
    end
  end

  actions do
    default_accept [:content, :date, :image_url, :user_id]
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "post"

    routes do
      base "/posts"

      get :read
      index :read
      post :create
      patch :update, route: "/:id"
      delete :destroy, route: "/:id"
    end
  end

  graphql do
    type :post

    queries do
      get :post, :read
      list :posts, :read
    end

    mutations do
      create :create_post, :create
      update :update_post, :update
      destroy :delete_post, :destroy
    end
  end
end
