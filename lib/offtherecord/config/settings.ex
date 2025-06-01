defmodule Offtherecord.Config.Settings do
  @moduledoc """
  Application configuration settings loaded from environment variables.

  This module centralizes all environment variable configurations
  and provides typed access to application settings.
  """

  alias Offtherecord.Config.Env

  @doc """
  Gets database configuration from environment variables.
  """
  def database_config do
    %{
      url:
        Env.get_env("DATABASE_URL",
          required: Env.prod?(),
          description: "Database connection URL (PostgreSQL)"
        ),
      pool_size:
        Env.get_env("POOL_SIZE",
          default: "10",
          type: :integer,
          description: "Database connection pool size"
        ),
      ipv6:
        Env.get_env("ECTO_IPV6",
          default: "false",
          type: :boolean,
          description: "Enable IPv6 for database connections"
        )
    }
  end

  @doc """
  Gets Phoenix web server configuration from environment variables.
  """
  def web_config do
    %{
      secret_key_base:
        Env.get_env("SECRET_KEY_BASE",
          required: Env.prod?(),
          description: "Secret key base for signing/encrypting cookies and sessions"
        ),
      host:
        Env.get_env("PHX_HOST",
          default: if(Env.prod?(), do: "example.com", else: "localhost"),
          description: "Phoenix host for URL generation"
        ),
      port:
        Env.get_env("PORT",
          default: "4000",
          type: :integer,
          description: "HTTP port for Phoenix server"
        ),
      server:
        Env.get_env("PHX_SERVER",
          default: "false",
          type: :boolean,
          description: "Whether to start Phoenix server"
        ),
      signing_salt:
        Env.get_env("LIVE_VIEW_SIGNING_SALT",
          default: "default-signing-salt",
          description: "Signing salt for LiveView"
        )
    }
  end

  @doc """
  Gets OAuth configuration from environment variables.
  """
  def oauth_config do
    %{
      google: %{
        client_id:
          Env.get_env("GOOGLE_CLIENT_ID",
            default: "your-google-client-id",
            description: "Google OAuth client ID"
          ),
        client_secret:
          Env.get_env("GOOGLE_CLIENT_SECRET",
            default: "your-google-client-secret",
            description: "Google OAuth client secret"
          ),
        redirect_uri:
          Env.get_env("GOOGLE_REDIRECT_URI",
            default: build_oauth_redirect_uri("google"),
            description: "Google OAuth redirect URI"
          )
      },
      facebook: %{
        app_id:
          Env.get_env("FACEBOOK_APP_ID",
            default: "your-facebook-app-id",
            description: "Facebook OAuth app ID"
          ),
        app_secret:
          Env.get_env("FACEBOOK_APP_SECRET",
            default: "your-facebook-app-secret",
            description: "Facebook OAuth app secret"
          ),
        redirect_uri:
          Env.get_env("FACEBOOK_REDIRECT_URI",
            default: build_oauth_redirect_uri("facebook"),
            description: "Facebook OAuth redirect URI"
          )
      }
    }
  end

  @doc """
  Gets SMS/Twilio configuration from environment variables.
  """
  def sms_config do
    %{
      account_sid:
        Env.get_env("TWILIO_ACCOUNT_SID",
          description: "Twilio account SID for SMS functionality"
        ),
      auth_token:
        Env.get_env("TWILIO_AUTH_TOKEN",
          description: "Twilio auth token for SMS functionality"
        ),
      phone_number:
        Env.get_env("TWILIO_PHONE_NUMBER",
          description: "Twilio phone number for sending SMS"
        )
    }
  end

  @doc """
  Gets Cloudflare configuration from environment variables.
  """
  def cloudflare_config do
    %{
      api_token:
        Env.get_env("CLOUDFLARE_API_TOKEN",
          description: "Cloudflare API token for image uploads"
        ),
      account_id:
        Env.get_env("CLOUDFLARE_ACCOUNT_ID",
          description: "Cloudflare account ID for image uploads"
        )
    }
  end

  @doc """
  Gets authentication configuration from environment variables.
  """
  def auth_config do
    %{
      token_signing_secret:
        Env.get_env("TOKEN_SIGNING_SECRET",
          default: "change-this-to-a-real-secret-in-production",
          description: "Secret for signing authentication tokens"
        )
    }
  end

  @doc """
  Determines SMS provider based on available configuration.
  """
  def sms_provider do
    sms = sms_config()

    if sms.account_sid && sms.auth_token do
      :twilio
    else
      :test
    end
  end

  @doc """
  Checks if Cloudflare is configured.
  """
  def cloudflare_configured? do
    cf = cloudflare_config()
    cf.api_token && cf.account_id
  end

  @doc """
  Validates all required configurations for the current environment.
  """
  def validate_config! do
    if Env.prod?() do
      validate_production_config!()
    else
      validate_development_config!()
    end
  end

  # Private functions

  defp build_oauth_redirect_uri(provider) do
    web = web_config()

    # Environment-specific base URL logic
    base_url = case Env.prod?() do
      true ->
        # Production: use configured host (offtherecord.im)
        "https://#{web.host}"
      false ->
        # Development/Test: use localhost with port
        "http://localhost:#{web.port}"
    end

    redirect_uri = "#{base_url}/auth/user/#{provider}/callback"

    # Debug logging for clarity
    if !Env.prod?() do
      IO.puts("=== OAuth Redirect URI Debug ===")
      IO.puts("Environment: #{Mix.env()}")
      IO.puts("Provider: #{provider}")
      IO.puts("Generated URI: #{redirect_uri}")
      IO.puts("===============================")
    end

    redirect_uri
  end

  defp validate_production_config! do
    # Required for production
    required_envs = [
      "DATABASE_URL",
      "SECRET_KEY_BASE"
    ]

    Env.validate_required_envs(required_envs)

    # Validate configurations
    _db = database_config()
    _web = web_config()

    # Warn about missing optional configs
    warn_if_missing_optional_configs()
  end

  defp validate_development_config! do
    # For development, we just validate what we can
    _db = database_config()
    _web = web_config()

    # Check if .env file exists
    unless File.exists?(".env") do
      IO.warn("""
      No .env file found. You may want to create one based on .env.example:
        cp .env.example .env
      """)
    end
  end

  defp warn_if_missing_optional_configs do
    # Warn about Cloudflare
    unless cloudflare_configured?() do
      IO.warn("Cloudflare Images not configured - image uploads may not work")
    end

    # Warn about SMS
    if sms_provider() == :test do
      IO.warn("Twilio SMS not configured - using test SMS provider")
    end
  end
end
