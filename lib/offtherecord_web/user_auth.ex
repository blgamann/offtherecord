defmodule OfftherecordWeb.UserAuth do
  @moduledoc """
  Helpers for user authentication in LiveView and Plugs.
  """
  import Phoenix.Component
  import Phoenix.LiveView
  import Plug.Conn
  import Phoenix.Controller

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, opts) do
    apply(__MODULE__, opts, [conn, []])
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if get_session(conn, "user_token") do
      conn
      |> Phoenix.Controller.redirect(to: "/dashboard")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if get_session(conn, "user_token") do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You must be logged in to access this page")
      |> Phoenix.Controller.redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Fetch the current user from the session and assign it to the connection.
  """
  def fetch_current_user(conn, _opts) do
    token = get_session(conn, "user_token")
    user = token && get_user_by_session_token(token)
    Plug.Conn.assign(conn, :current_user, user)
  end

  defp get_user_by_session_token(token) do
    case extract_user_id_from_token(token) do
      {:ok, user_id} ->
        case load_user(user_id) do
          {:ok, user} -> user
          {:error, _} -> nil
        end

      :error ->
        nil
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case session do
      %{"user_token" => token} when is_binary(token) ->
        # Extract user ID from token format "user_token_<uuid>"
        case extract_user_id_from_token(token) do
          {:ok, user_id} ->
            case load_user(user_id) do
              {:ok, user} ->
                socket = Phoenix.Component.assign(socket, :current_user, user)
                {:cont, socket}

              {:error, _} ->
                socket =
                  socket
                  |> Phoenix.LiveView.put_flash(
                    :error,
                    "You must be logged in to access this page"
                  )
                  |> Phoenix.LiveView.redirect(to: "/login")

                {:halt, socket}
            end

          :error ->
            socket =
              socket
              |> Phoenix.LiveView.put_flash(:error, "You must be logged in to access this page")
              |> Phoenix.LiveView.redirect(to: "/login")

            {:halt, socket}
        end

      _ ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You must be logged in to access this page")
          |> Phoenix.LiveView.redirect(to: "/login")

        {:halt, socket}
    end
  end

  defp extract_user_id_from_token("user_token_" <> user_id), do: {:ok, user_id}
  # For tests
  defp extract_user_id_from_token("test_token_" <> user_id), do: {:ok, user_id}
  defp extract_user_id_from_token(_), do: :error

  defp load_user(user_id) do
    case Ash.get(Offtherecord.Accounts.User, user_id, domain: Offtherecord.Accounts) do
      {:ok, user} -> {:ok, user}
      _ -> {:error, :not_found}
    end
  end
end
