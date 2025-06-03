defmodule Offtherecord.Config do
  @moduledoc """
  Application configuration management module.

  This module provides a centralized way to manage environment variables
  and application configuration with proper validation and defaults.
  """

  @doc """
  Gets the Cloudflare Images configuration.
  """
  def cloudflare_config do
    %{
      api_token: get_required_env("CLOUDFLARE_API_TOKEN"),
      account_id: get_required_env("CLOUDFLARE_ACCOUNT_ID")
    }
  end

  @doc """
  Gets the Twilio SMS configuration.
  """
  def twilio_config do
    %{
      account_sid: get_required_env("TWILIO_ACCOUNT_SID"),
      auth_token: get_required_env("TWILIO_AUTH_TOKEN"),
      phone_number: get_required_env("TWILIO_PHONE_NUMBER")
    }
  end

  @doc """
  Gets the Google OAuth configuration.
  """
  def google_oauth_config do
    %{
      client_id: get_required_env("GOOGLE_CLIENT_ID"),
      client_secret: get_required_env("GOOGLE_CLIENT_SECRET"),
      redirect_uri: get_required_env("GOOGLE_REDIRECT_URI")
    }
  end

  @doc """
  Gets the authentication configuration.
  """
  def auth_config do
    %{
      signing_secret: get_required_env("TOKEN_SIGNING_SECRET"),
      live_view_signing_salt: get_env("LIVE_VIEW_SIGNING_SALT", generate_dev_salt())
    }
  end

  @doc """
  Gets the database configuration.
  """
  def database_config do
    case Mix.env() do
      :prod ->
        %{
          url: get_required_env("DATABASE_URL"),
          pool_size: get_env("POOL_SIZE", "10") |> String.to_integer(),
          ipv6: get_env("ECTO_IPV6") in ~w(true 1)
        }

      _ ->
        %{
          username: get_env("DB_USERNAME", "postgres"),
          password: get_env("DB_PASSWORD", "postgres"),
          hostname: get_env("DB_HOSTNAME", "localhost"),
          database: get_env("DB_DATABASE", "offtherecord_#{Mix.env()}"),
          pool_size: get_env("DB_POOL_SIZE", "10") |> String.to_integer()
        }
    end
  end

  @doc """
  Gets the web server configuration.
  """
  def server_config do
    case Mix.env() do
      :prod ->
        %{
          host: get_env("PHX_HOST", "example.com"),
          port: get_env("PORT", "4000") |> String.to_integer(),
          secret_key_base: get_required_env("SECRET_KEY_BASE"),
          dns_cluster_query: get_env("DNS_CLUSTER_QUERY")
        }

      _ ->
        %{
          host: get_env("PHX_HOST", "localhost"),
          port: get_env("PORT", "4000") |> String.to_integer(),
          secret_key_base: get_env("SECRET_KEY_BASE", generate_dev_secret())
        }
    end
  end

  @doc """
  Determines the SMS provider based on available configuration.
  """
  def sms_provider do
    twilio = twilio_config()

    if twilio.account_sid && twilio.auth_token do
      :twilio
    else
      :test
    end
  end

  @doc """
  Validates that all required environment variables are present.
  Raises an error if any required variables are missing.
  """
  def validate_required_config! do
    case Mix.env() do
      :prod ->
        validate_production_config!()

      :test ->
        validate_test_config!()

      _ ->
        validate_development_config!()
    end
  end

  # Private functions

  defp get_env(key, default \\ nil) do
    System.get_env(key) || default
  end

  defp get_required_env(key) do
    case System.get_env(key) do
      nil ->
        raise """
        environment variable #{key} is missing.
        Please set this variable in your environment or .env file.
        """

      value ->
        value
    end
  end

  defp generate_dev_salt do
    "dev-salt-#{System.system_time()}"
  end

  defp generate_dev_secret do
    "Ezvjj1lXmgdaJ9vB3hrSDZSe7D/sh4X5I/Yx0PUsMVdxnMPGXhZGnmoa+8qtnnHL"
  end

  defp validate_production_config! do
    required_vars = [
      "DATABASE_URL",
      "SECRET_KEY_BASE",
      "CLOUDFLARE_API_TOKEN",
      "GOOGLE_CLIENT_ID",
      "GOOGLE_CLIENT_SECRET",
      "TOKEN_SIGNING_SECRET"
    ]

    missing = Enum.filter(required_vars, &is_nil(System.get_env(&1)))

    unless Enum.empty?(missing) do
      raise """
      Missing required environment variables for production:
      #{Enum.join(missing, ", ")}
      """
    end
  end

  defp validate_test_config! do
    # In test environment, we might want to validate some specific test configs
    :ok
  end

  defp validate_development_config! do
    # Check if critical development configs are available
    # For development, we're more lenient but still warn about missing configs
    cloudflare = cloudflare_config()

    if is_nil(cloudflare.api_token) do
      IO.puts("""
      ⚠️  CLOUDFLARE_API_TOKEN is not set.
      Image upload functionality will not work.
      Please add CLOUDFLARE_API_TOKEN to your .env file.
      """)
    end

    twilio = twilio_config()

    if is_nil(twilio.account_sid) || is_nil(twilio.auth_token) do
      IO.puts("""
      ⚠️  Twilio credentials are not set.
      SMS will be sent in test mode (console output only).
      To enable real SMS, add TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN to your .env file.
      """)
    end

    :ok
  end
end
