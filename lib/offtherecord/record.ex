defmodule Offtherecord.Record do
  use Ash.Domain

  resources do
    resource Offtherecord.Record.Post
  end
end
