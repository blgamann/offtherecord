defmodule Offtherecord.Record.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Offtherecord.Record,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource],
    authorizers: [Ash.Policy.Authorizer]

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

  postgres do
    table "posts"
    repo Offtherecord.Repo
  end

  actions do
    default_accept [:content, :date, :image_url]
    defaults [:update, :destroy]

    read :read do
      primary? true

      prepare fn query, _context ->
        query
      end
    end

    create :create do
      accept [:content, :date, :image_url]

      change fn changeset, context ->
        case context.actor do
          %{id: user_id} ->
            Ash.Changeset.change_attribute(changeset, :user_id, user_id)

          _ ->
            Ash.Changeset.add_error(changeset, "User must be authenticated")
        end
      end
    end
  end

  # Policy for private records - users can only access their own posts
  policies do
    # All actions require authentication
    policy action_type([:read, :create, :update, :destroy]) do
      authorize_if actor_present()
    end

    # Read, update, and destroy actions require ownership
    policy action_type([:read, :update, :destroy]) do
      authorize_if relates_to_actor_via(:user)
    end
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
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Offtherecord.Accounts.User do
      allow_nil? false
      public? true
    end
  end
end
