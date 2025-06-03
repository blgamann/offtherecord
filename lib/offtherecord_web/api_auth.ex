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
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Unauthorized"})
        |> halt()
    end
  end

  defp extract_user_id_from_token(token) do
    case Offtherecord.Accounts.Token.verify(token) do
      {:ok, %{"user_id" => user_id}} -> {:ok, user_id}
      _ -> :error
    end
  end

  defp load_user(user_id) do
    case Ash.get(Offtherecord.Accounts.User, user_id, domain: Offtherecord.Accounts) do
      {:ok, user} -> {:ok, user}
      _ -> {:error, :not_found}
    end
  end
end
