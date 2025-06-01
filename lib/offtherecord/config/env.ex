defmodule Offtherecord.Config.Env do
  @moduledoc """
  Centralized environment variable management for Offtherecord application.

  This module provides a unified way to:
  - Fetch environment variables with validation
  - Provide default values
  - Type conversion and validation
  - Better error messages for missing required variables
  """

  @doc """
  Gets an environment variable with validation.

  ## Options
  - `:required` - Whether the environment variable is required (default: false)
  - `:default` - Default value if the environment variable is not set
  - `:type` - Type to convert to (:string, :integer, :boolean, :url)
  - `:description` - Description for error messages

  ## Examples

      iex> get_env("DATABASE_URL", required: true, type: :url)
      "postgresql://user:pass@localhost/db"
      
      iex> get_env("PORT", default: "4000", type: :integer)
      4000
      
      iex> get_env("DEBUG", default: "false", type: :boolean)
      false
  """
  def get_env(name, opts \\ []) do
    required = Keyword.get(opts, :required, false)
    default = Keyword.get(opts, :default)
    type = Keyword.get(opts, :type, :string)
    description = Keyword.get(opts, :description, name)

    case System.get_env(name) do
      nil when required ->
        raise_missing_env_error(name, description)

      nil ->
        convert_type(default, type)

      value ->
        convert_type(value, type)
    end
  end

  @doc """
  Gets multiple environment variables at once with validation.

  ## Examples

      iex> get_envs([
      ...>   {"DATABASE_URL", [required: true, type: :url]},
      ...>   {"PORT", [default: "4000", type: :integer]},
      ...>   {"DEBUG", [default: "false", type: :boolean]}
      ...> ])
      %{
        database_url: "postgresql://user:pass@localhost/db",
        port: 4000,
        debug: false
      }
  """
  def get_envs(env_configs) do
    env_configs
    |> Enum.map(fn {name, opts} ->
      key = name |> String.downcase() |> String.replace("_", "_") |> String.to_atom()
      value = get_env(name, opts)
      {key, value}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Validates that all required environment variables are present.
  Useful for startup checks.
  """
  def validate_required_envs(env_list) do
    missing_envs =
      env_list
      |> Enum.filter(fn name -> is_nil(System.get_env(name)) end)

    unless Enum.empty?(missing_envs) do
      raise """
      Missing required environment variables:
      #{Enum.map_join(missing_envs, "\n", &"  - #{&1}")}

      Please set these environment variables and try again.

      For development, check your .env file.
      For production (fly.io), use: flyctl secrets set VARIABLE_NAME=value
      """
    end
  end

  @doc """
  Gets environment-specific configuration.
  """
  def get_env_config() do
    case get_env("MIX_ENV", default: "dev") do
      env when env in ["dev", "development"] -> :dev
      env when env in ["test", "testing"] -> :test
      env when env in ["prod", "production"] -> :prod
      _ -> :dev
    end
  end

  @doc """
  Checks if we're running in production environment.
  """
  def prod?(), do: get_env_config() == :prod

  @doc """
  Checks if we're running in development environment.
  """
  def dev?(), do: get_env_config() == :dev

  @doc """
  Checks if we're running in test environment.
  """
  def test?(), do: get_env_config() == :test

  # Private functions

  defp convert_type(nil, _type), do: nil
  defp convert_type(value, :string), do: value

  defp convert_type(value, :integer) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> raise ArgumentError, "Invalid integer: #{value}"
    end
  end

  defp convert_type(value, :integer), do: value

  defp convert_type(value, :boolean) when is_binary(value) do
    case String.downcase(value) do
      v when v in ["true", "1", "yes", "on"] -> true
      v when v in ["false", "0", "no", "off"] -> false
      _ -> raise ArgumentError, "Invalid boolean: #{value}"
    end
  end

  defp convert_type(value, :boolean), do: value

  defp convert_type(value, :url) do
    case URI.parse(value) do
      %URI{scheme: scheme} when scheme in ["http", "https", "postgresql", "postgres"] ->
        value

      _ ->
        raise ArgumentError, "Invalid URL: #{value}"
    end
  end

  defp raise_missing_env_error(name, description) do
    env_type = get_env_config()

    message =
      case env_type do
        :prod ->
          """
          Missing required environment variable: #{name}
          Description: #{description}

          For fly.io deployment, set this using:
            flyctl secrets set #{name}=your_value

          To see current secrets:
            flyctl secrets list
          """

        :dev ->
          """
          Missing required environment variable: #{name}
          Description: #{description}

          For development, add this to your .env file:
            #{name}=your_value

          Check .env.example for reference values.
          """

        :test ->
          """
          Missing required environment variable: #{name}
          Description: #{description}

          For testing, either:
          1. Add #{name}=test_value to your .env file
          2. Set it in config/test.exs
          3. Use Application.put_env/3 in your test setup
          """
      end

    raise message
  end
end
