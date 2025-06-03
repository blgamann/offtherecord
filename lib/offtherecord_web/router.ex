defmodule OfftherecordWeb.Router do
  use OfftherecordWeb, :router
  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OfftherecordWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug OfftherecordWeb.UserAuth, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug OfftherecordWeb.UserAuth, :fetch_current_user
  end

  pipeline :graphql do
    plug AshGraphql.Plug
  end

  pipeline :authenticated do
    plug OfftherecordWeb.UserAuth, :require_authenticated_user
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug OfftherecordWeb.ApiAuth
  end

  scope "/", OfftherecordWeb do
    pipe_through :browser

    get "/auth/sms/success", AuthGoogleController, :sms_login_success, as: :sms_success
    auth_routes(AuthGoogleController, Offtherecord.Accounts.User, path: "/auth")
    sign_out_route(AuthGoogleController)

    live "/login", AuthLive, :login
    live "/sms-login", SmsAuthLive, :index
  end

  # routes for browser access
  scope "/", OfftherecordWeb do
    pipe_through [:browser, :authenticated]

    live "/", PostsLive, :index
  end

  # routes for mobile/external access
  scope "/api", OfftherecordWeb do
    pipe_through :api

    post "/auth/google", ApiGoogleAuthController, :google_auth
    post "/auth/verify", ApiGoogleAuthController, :verify_token
    delete "/auth/logout", ApiGoogleAuthController, :logout
  end

  # API routes with authentication
  scope "/api" do
    pipe_through :api_auth

    forward "/json", AshJsonApi.Controllers.Router, domains: [Offtherecord.Record]
  end

  # GraphQL endpoint
  scope "/graphql" do
    pipe_through :api

    forward "/", Absinthe.Plug, schema: OfftherecordWeb.Schema
  end

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
