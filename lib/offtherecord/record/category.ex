defmodule Offtherecord.Record.Category do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Offtherecord.Record,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource],
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  graphql do
    type :category

    queries do
      list :categories, :read
    end

    mutations do
      create :create_category, :create
      update :update_category, :update
      destroy :delete_category, :destroy
    end
  end

  json_api do
    type "category"

    routes do
      base "/categories"
      get :read
      index :read
      post :create
      patch :update, route: "/:id"
      delete :destroy, route: "/:id"
    end
  end

  postgres do
    table "categories"
    repo Offtherecord.Repo

    references do
      reference :user, on_delete: :delete, on_update: :update
    end
  end

  actions do
    default_accept [:name]
    defaults [:update, :destroy]

    read :read do
      primary? true
      pagination keyset?: true, required?: false
    end

    create :create do
      accept [:name]

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

  # Policy for private categories - users can only access their own categories
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

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints max_length: 100
    end

    attribute :user_id, :uuid do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Offtherecord.Accounts.User do
      allow_nil? false
      public? true
    end

    has_many :posts, Offtherecord.Record.Post do
      public? true
    end
  end

  # Ensure unique category names per user
  identities do
    identity :unique_name_per_user, [:user_id, :name]
  end
end
