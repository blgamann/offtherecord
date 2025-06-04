defmodule Offtherecord.Accounts.User do
  use Ash.Resource,
    extensions: [AshAuthentication],
    domain: Offtherecord.Accounts,
    data_layer: AshPostgres.DataLayer

  authentication do
    strategies do
      google do
        client_id(fn _secret_name, _resource ->
          {:ok, System.get_env("GOOGLE_CLIENT_ID")}
        end)

        client_secret(fn _secret_name, _resource ->
          {:ok, System.get_env("GOOGLE_CLIENT_SECRET")}
        end)

        redirect_uri(fn _secret_name, _resource ->
          {:ok, System.get_env("GOOGLE_REDIRECT_URI")}
        end)
      end
    end

    tokens do
      enabled?(true)
      token_resource(Offtherecord.Accounts.Token)

      signing_secret(fn _secret_name, _resource ->
        {:ok,
         System.get_env("TOKEN_SIGNING_SECRET") || "change-this-to-a-real-secret-in-production"}
      end)
    end
  end

  postgres do
    table "users"
    repo Offtherecord.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:email, :name, :picture]
    end

    update :update do
      accept [:email, :name, :picture]
    end

    # https://hexdocs.pm/ash_authentication/google.html
    create :register_with_google do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false

      accept [:email, :name, :picture]
      upsert? true
      upsert_identity :unique_email

      change AshAuthentication.GenerateTokenChange

      change fn changeset, _ctx ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)

        changeset
        |> Ash.Changeset.change_attribute(:email, user_info["email"])
        |> Ash.Changeset.change_attribute(:name, user_info["name"])
        |> Ash.Changeset.change_attribute(:picture, user_info["picture"])
      end
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: true, public?: true
    attribute :name, :string, public?: true
    attribute :picture, :string, public?: true
    timestamps()
  end

  relationships do
    has_many :posts, Offtherecord.Record.Post do
      public? true
    end
  end

  identities do
    identity :unique_email, [:email]
  end
end
