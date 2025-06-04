import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# Load .env file in development environment
if config_env() == :dev do
  try do
    case Code.ensure_loaded(Dotenv) do
      {:module, Dotenv} ->
        Dotenv.load!()
        IO.puts("=== .env file loaded successfully ===")

      {:error, _} ->
        IO.puts("Dotenv module not available at runtime")
    end
  rescue
    error ->
      IO.puts("Failed to load .env at runtime: #{inspect(error)}")
  end
end

# Import our configuration modules
alias Offtherecord.Config.Settings

# Validate configuration for current environment
try do
  Settings.validate_config!()
  IO.puts("=== Configuration validation passed ===")
rescue
  error ->
    IO.puts("Configuration validation failed: #{error.message}")

    if config_env() == :prod do
      # In production, we should fail fast
      raise error
    end
end

# Get configurations
db_config = Settings.database_config()
web_config = Settings.web_config()
oauth_config = Settings.oauth_config()
cloudflare_config = Settings.cloudflare_config()
auth_config = Settings.auth_config()

# Configure Cloudflare (for all environments if configured)
if Settings.cloudflare_configured?() do
  config :offtherecord, :cloudflare,
    api_token: cloudflare_config.api_token,
    account_id: cloudflare_config.account_id

  IO.puts("=== Cloudflare Images configured ===")
else
  IO.puts("=== Cloudflare Images not configured - using fallback ===")
end

# Configure Google OAuth
config :offtherecord, AshAuthentication.Strategy.Google,
  client_id: oauth_config.google.client_id,
  client_secret: oauth_config.google.client_secret,
  redirect_uri: oauth_config.google.redirect_uri

# Debug: Log the actual OAuth configuration being used
IO.puts("=== OAuth Debug Info ===")
IO.puts("Google Client ID: #{String.slice(oauth_config.google.client_id || "nil", 0, 10)}...")
IO.puts("Google Redirect URI: #{oauth_config.google.redirect_uri || "nil"}")
IO.puts("========================")

# Configure AshAuthentication
config :offtherecord, AshAuthentication, signing_secret: auth_config.token_signing_secret

# Enable Phoenix server if requested
if web_config.server do
  config :offtherecord, OfftherecordWeb.Endpoint, server: true
end

# Production-specific configuration
if config_env() == :prod do
  IO.puts("=== Configuring for production environment ===")

  maybe_ipv6 = if db_config.ipv6, do: [:inet6], else: []

  # Database configuration
  config :offtherecord, Offtherecord.Repo,
    url: db_config.url,
    pool_size: db_config.pool_size,
    socket_options: maybe_ipv6

  # Phoenix endpoint configuration
  config :offtherecord, OfftherecordWeb.Endpoint,
    url: [host: web_config.host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: web_config.port
    ],
    secret_key_base: web_config.secret_key_base,
    check_origin: [
      "https://offtherecord.im",
      "https://offtherecord.fly.dev",
      "//offtherecord.im",
      "//offtherecord.fly.dev"
    ]

  # Configure DNS cluster if specified
  if dns_query = System.get_env("DNS_CLUSTER_QUERY") do
    config :offtherecord, :dns_cluster_query, dns_query
  end

  IO.puts("=== Production configuration completed ===")

  # Log configuration summary (without sensitive data)
  IO.puts("""
  === Configuration Summary ===
  Host: #{web_config.host}
  Port: #{web_config.port}
  Database Pool Size: #{db_config.pool_size}
  IPv6: #{db_config.ipv6}
  Cloudflare: #{if Settings.cloudflare_configured?(), do: "enabled", else: "disabled"}
  ============================
  """)
end
