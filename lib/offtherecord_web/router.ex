defmodule OfftherecordWeb.Router do
  use OfftherecordWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :graphql do
    plug AshGraphql.Plug
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OfftherecordWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug OfftherecordWeb.UserAuth, :fetch_current_user
  end

  pipeline :require_authenticated_user do
    plug OfftherecordWeb.UserAuth, :require_authenticated_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/gql" do
    pipe_through [:graphql]

    forward "/playground", Absinthe.Plug.GraphiQL,
      schema: Module.concat(["OfftherecordWeb.GraphqlSchema"]),
      socket: Module.concat(["OfftherecordWeb.GraphqlSocket"]),
      interface: :simple

    forward "/", Absinthe.Plug, schema: Module.concat(["OfftherecordWeb.GraphqlSchema"])
  end

  scope "/api/json" do
    pipe_through [:api]

    forward "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
      path: "/api/json/open_api",
      default_model_expand_depth: 4

    forward "/", OfftherecordWeb.AshJsonApiRouter
  end

  scope "/", OfftherecordWeb do
    pipe_through :browser

    get "/auth/sms/success", AuthController, :sms_login_success, as: :sms_success
    auth_routes(AuthController, Offtherecord.Accounts.User, path: "/auth")
    sign_out_route(AuthController)

    get "/", PageController, :home
    live "/login", AuthLive, :login
    live "/sms-login", SmsAuthLive, :index
  end

  scope "/", OfftherecordWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/dashboard", DashboardLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", OfftherecordWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:offtherecord, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OfftherecordWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
