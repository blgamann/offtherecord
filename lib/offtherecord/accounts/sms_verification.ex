defmodule Offtherecord.Accounts.SmsVerification do
  use Ash.Resource,
    domain: Offtherecord.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "sms_verifications"
    repo Offtherecord.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:phone_number, :code, :expires_at]
    end

    update :update do
      primary? true
      accept [:verified_at, :attempts]
    end

    destroy :destroy do
      primary? true
    end

    read :get_by_phone_and_code do
      argument :phone_number, :string, allow_nil?: false
      argument :code, :string, allow_nil?: false

      filter expr(
               phone_number == ^arg(:phone_number) and code == ^arg(:code) and is_nil(verified_at) and
                 expires_at > now()
             )
    end

    read :get_valid_by_phone do
      argument :phone_number, :string, allow_nil?: false

      filter expr(
               phone_number == ^arg(:phone_number) and is_nil(verified_at) and
                 expires_at > now()
             )

      prepare build(sort: [created_at: :desc], limit: 1)
    end
  end

  validations do
    validate compare(:expires_at, greater_than: &DateTime.utc_now/0), on: [:create]
    validate compare(:attempts, less_than: 6), message: "너무 많은 시도입니다. 잠시 후 다시 시도해주세요."
  end

  attributes do
    uuid_primary_key :id
    attribute :phone_number, :string, allow_nil?: false, public?: true
    attribute :code, :string, allow_nil?: false
    attribute :expires_at, :utc_datetime, allow_nil?: false
    attribute :verified_at, :utc_datetime, public?: true
    attribute :attempts, :integer, default: 0, public?: true
    timestamps()
  end

  identities do
    identity :unique_phone_code, [:phone_number, :code]
  end
end
