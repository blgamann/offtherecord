defmodule OfftherecordWeb.AuthController do
  use OfftherecordWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/dashboard"

    # Generate a simple token for session
    token = "user_token_#{user.id}"

    conn
    |> delete_session(:return_to)
    |> put_session("user_token", token)
    |> assign(:current_user, user)
    |> put_flash(:info, "로그인되었습니다!")
    |> redirect(to: return_to)
  end

  def failure(conn, _activity, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/login")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session()
    |> put_flash(:info, "로그아웃되었습니다.")
    |> redirect(to: return_to)
  end

  def sms_login_success(conn, %{"user_id" => user_id}) do
    case Offtherecord.Accounts.User
         |> Ash.get(user_id, domain: Offtherecord.Accounts) do
      {:ok, user} ->
        # Generate a simple token for session
        token = "user_token_#{user.id}"

        conn
        |> put_session("user_token", token)
        |> assign(:current_user, user)
        |> put_flash(:info, "로그인되었습니다!")
        |> redirect(to: ~p"/dashboard")

      {:error, _} ->
        conn
        |> put_flash(:error, "사용자를 찾을 수 없습니다.")
        |> redirect(to: ~p"/login")
    end
  end

  # Handle missing user_id parameter
  def sms_login_success(conn, _params) do
    conn
    |> put_flash(:error, "사용자를 찾을 수 없습니다.")
    |> redirect(to: ~p"/login")
  end
end
