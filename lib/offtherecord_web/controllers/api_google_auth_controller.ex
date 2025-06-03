defmodule OfftherecordWeb.ApiGoogleAuthController do
  use OfftherecordWeb, :controller
  alias Offtherecord.Accounts.User

  def google_auth(conn, %{"access_token" => access_token}) do
    case verify_google_token(access_token) do
      {:ok, user_info} ->
        case find_or_create_user(user_info) do
          {:ok, user} ->
            token = generate_session_token(user.id)

            conn
            |> json(%{
              success: true,
              token: token
            })

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "사용자 생성에 실패했습니다.", details: inspect(changeset)})
        end

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Google 토큰 검증에 실패했습니다: #{reason}"})
    end
  end

  def google_auth(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "access_token이 필요합니다."})
  end

  def verify_token(conn, %{"token" => token}) do
    case extract_user_id_from_token(token) do
      {:ok, user_id} ->
        case load_user(user_id) do
          {:ok, user} ->
            conn
            |> json(%{
              valid: true,
              user: %{
                id: user.id,
                email: user.email,
                name: user.name,
                picture: user.picture
              }
            })

          {:error, _} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{valid: false, error: "사용자를 찾을 수 없습니다."})
        end

      :error ->
        conn
        |> put_status(:unauthorized)
        |> json(%{valid: false, error: "유효하지 않은 토큰입니다."})
    end
  end

  def verify_token(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "token이 필요합니다."})
  end

  def logout(conn, _params) do
    conn
    |> delete_session("user_token")
    |> json(%{success: true, message: "로그아웃되었습니다."})
  end

  defp verify_google_token(access_token) do
    url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{access_token}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, user_info} ->
            {:ok, user_info}

          {:error, _} ->
            {:error, "응답 파싱 실패"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "HTTP 오류: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "네트워크 오류: #{reason}"}
    end
  end

  defp find_or_create_user(user_info) do
    User
    |> Ash.Changeset.for_create(:register_with_google, %{
      user_info: user_info,
      oauth_tokens: %{}
    })
    |> Ash.create(domain: Offtherecord.Accounts)
  end

  defp generate_session_token(user_id) do
    "user_token_#{user_id}"
  end

  defp extract_user_id_from_token("user_token_" <> user_id), do: {:ok, user_id}
  defp extract_user_id_from_token(_), do: :error

  defp load_user(user_id) do
    case Ash.get(User, user_id, domain: Offtherecord.Accounts) do
      {:ok, user} -> {:ok, user}
      _ -> {:error, :not_found}
    end
  end
end
