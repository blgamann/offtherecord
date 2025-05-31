defmodule Offtherecord.Record do
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  resources do
    resource Offtherecord.Record.Post
  end
end
