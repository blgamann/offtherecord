defmodule OfftherecordWeb.AshJsonApiRouter do
  use AshJsonApi.Router,
    domains: [Offtherecord.Record],
    open_api: "/open_api"
end
