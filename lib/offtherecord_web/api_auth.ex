defmodule OfftherecordWeb.ApiAuth do
  @moduledoc """
  Handles API authentication using tokens.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <- extract_user_id_from_token(token),
         {:ok, user} <- load_user(user_id) do
      conn
      |> assign(:current_user, user)
      |> Ash.PlugHelpers.set_actor(user)
    else
      _error ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Unauthorized"})
        |> halt()
    end
  end

  def get_current_user(conn) do
    conn.assigns[:current_user]
  end

  defp extract_user_id_from_token("user_token_" <> user_id), do: {:ok, user_id}
  defp extract_user_id_from_token(_), do: :error

  defp load_user(user_id) do
    case Ash.get(Offtherecord.Accounts.User, user_id, domain: Offtherecord.Accounts) do
      {:ok, user} -> {:ok, user}
      _ -> {:error, :not_found}
    end
  end
end
