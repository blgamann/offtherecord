defmodule Offtherecord.Record do
  use Ash.Domain, extensions: [AshJsonApi.Domain, AshAi.Domain]

  resources do
    resource Offtherecord.Record.Post
    resource Offtherecord.Record.Category
  end
end
