defmodule Offtherecord.Record.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Offtherecord.Record,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource, AshAi],
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  graphql do
    type :post

    queries do
      get :post, :read
      list :posts, :read
      list :search_posts, :search, description: "Search posts using semantic search"
    end

    mutations do
      create :create_post, :create
      update :update_post, :update
      update :assign_post_category, :assign_category
      destroy :delete_post, :destroy
    end
  end

  json_api do
    type "post"

    routes do
      base "/posts"

      get :read
      index :read
      index :search, route: "/search"
      post :create
      patch :update, route: "/:id"
      delete :destroy, route: "/:id"
    end
  end

  postgres do
    table "posts"
    repo Offtherecord.Repo
  end

  # Vectorization for AI-powered search
  vectorize do
    full_text do
      text(fn post ->
        """
        Content: #{post.content}
        """
      end)
    end

    # :manual, :ash_oban
    strategy :after_action
    embedding_model(Offtherecord.Ai.OpenAiEmbeddingModel)
  end

  actions do
    default_accept [:content, :date, :image_url, :category_id]
    defaults [:update, :destroy]

    read :read do
      primary? true
      pagination keyset?: true, required?: false
    end

    create :create do
      accept [:content, :date, :image_url, :category_id]

      change fn changeset, context ->
        case context.actor do
          %{id: user_id} ->
            Ash.Changeset.change_attribute(changeset, :user_id, user_id)

          _ ->
            Ash.Changeset.add_error(changeset, "User must be authenticated")
        end
      end
    end

    # Vector search action for semantic search
    read :search do
      argument :query, :string do
        allow_nil? false
        description "Search query for semantic search"
      end

      argument :limit, :integer do
        allow_nil? true
        default 10
        description "Maximum number of results"
      end

      prepare fn query, _context ->
        case query.arguments do
          %{query: search_query} when is_binary(search_query) ->
            case Offtherecord.Ai.OpenAiEmbeddingModel.generate([search_query], []) do
              {:ok, [search_vector]} ->
                # 일단 간단한 필터링만 적용 (벡터 연산은 나중에)
                query
                |> Ash.Query.filter(not is_nil(full_text_vector))
                |> Ash.Query.limit(query.arguments[:limit] || 10)

              {:error, error} ->
                Ash.Query.add_error(query, error)
            end

          _ ->
            query
        end
      end

      pagination keyset?: true, required?: false
    end

    # Action to assign category to post
    update :assign_category do
      accept [:category_id]
    end
  end

  # Policy for private records - users can only access their own posts
  policies do
    # Allow AshAi to update embeddings first (before other policies)
    bypass action(:ash_ai_update_embeddings) do
      authorize_if AshAi.Checks.ActorIsAshAi
    end

    # All actions require authentication
    policy action_type([:read, :create, :update, :destroy]) do
      authorize_if actor_present()
    end

    # Read, update, and destroy actions require ownership
    policy action_type([:read, :update, :destroy]) do
      authorize_if relates_to_actor_via(:user)
    end

    # Search action also requires ownership
    policy action(:search) do
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

    attribute :category_id, :uuid do
      allow_nil? true
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

    belongs_to :category, Offtherecord.Record.Category do
      allow_nil? true
      public? true
    end
  end
end
