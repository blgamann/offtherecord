defmodule Offtherecord.Accounts do
  use Ash.Domain

  resources do
    resource Offtherecord.Accounts.User
    resource Offtherecord.Accounts.Token
  end
end
