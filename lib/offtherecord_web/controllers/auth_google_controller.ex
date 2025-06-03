defmodule OfftherecordWeb.AuthGoogleController do
  use OfftherecordWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"
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
end
