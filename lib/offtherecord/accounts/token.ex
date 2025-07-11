defmodule Offtherecord.Accounts.Token do
  use Ash.Resource,
    extensions: [AshAuthentication.TokenResource],
    domain: Offtherecord.Accounts,
    data_layer: AshPostgres.DataLayer

  token do
    domain Offtherecord.Accounts
  end

  postgres do
    table "tokens"
    repo Offtherecord.Repo
  end
end
