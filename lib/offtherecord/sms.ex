defmodule Offtherecord.SMS do
  @moduledoc """
  SMS 발송 및 인증 코드 관리 모듈
  """

  require Logger
  alias Offtherecord.Accounts.SmsVerification
  alias Offtherecord.Accounts

  @verification_code_length 6
  @verification_expires_in_minutes 5

  @doc """
  핸드폰 번호로 인증 코드 SMS를 발송합니다.
  """
  def send_verification_code(phone_number) do
    # 기존 미인증 코드 삭제
    cleanup_old_codes(phone_number)

    # 새 인증 코드 생성
    code = generate_verification_code()
    expires_at = DateTime.add(DateTime.utc_now(), @verification_expires_in_minutes * 60, :second)

    # 데이터베이스에 저장
    case create_verification_record(phone_number, code, expires_at) do
      {:ok, _verification} ->
        # SMS 발송
        send_sms(phone_number, code)

      {:error, error} ->
        Logger.error("SMS 인증 코드 저장 실패: #{inspect(error)}")
        {:error, "인증 코드 생성에 실패했습니다."}
    end
  end

  @doc """
  인증 코드를 검증합니다.
  """
  def verify_code(phone_number, code) do
    # SmsVerification 리소스에서 정의된 액션 사용
    case SmsVerification
         |> Ash.Query.for_read(:get_by_phone_and_code, %{
           phone_number: phone_number,
           code: code
         })
         |> Ash.read(domain: Accounts) do
      {:ok, [verification]} ->
        # 인증 성공 처리
        case Ash.update(verification, %{verified_at: DateTime.utc_now()}, domain: Accounts) do
          {:ok, _updated_verification} ->
            {:ok, :verified}

          {:error, error} ->
            Logger.error("인증 상태 업데이트 실패: #{inspect(error)}")
            {:error, "인증 처리 중 오류가 발생했습니다."}
        end

      {:ok, []} ->
        # 시도 횟수 증가
        increment_attempts(phone_number)
        {:error, "인증 코드가 올바르지 않거나 만료되었습니다."}

      {:error, error} ->
        Logger.error("인증 코드 검증 중 오류: #{inspect(error)}")
        {:error, "인증 코드 검증에 실패했습니다."}
    end
  end

  # Private functions

  defp generate_verification_code do
    1..@verification_code_length
    |> Enum.map(fn _ -> Enum.random(0..9) end)
    |> Enum.join()
  end

  defp create_verification_record(phone_number, code, expires_at) do
    SmsVerification
    |> Ash.Changeset.for_create(:create, %{
      phone_number: phone_number,
      code: code,
      expires_at: expires_at
    })
    |> Ash.create(domain: Accounts)
  end

  defp cleanup_old_codes(phone_number) do
    case SmsVerification
         |> Ash.Query.for_read(:get_valid_by_phone, %{phone_number: phone_number})
         |> Ash.read(domain: Accounts) do
      {:ok, verifications} ->
        Enum.each(verifications, fn verification ->
          Ash.destroy!(verification, domain: Accounts)
        end)

      _ ->
        :ok
    end
  end

  defp increment_attempts(phone_number) do
    case SmsVerification
         |> Ash.Query.for_read(:get_valid_by_phone, %{phone_number: phone_number})
         |> Ash.read(domain: Accounts) do
      {:ok, [verification]} ->
        case Ash.update(verification, %{attempts: verification.attempts + 1}, domain: Accounts) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            Logger.error("시도 횟수 증가 실패: #{inspect(error)}")
            :ok
        end

      _ ->
        :ok
    end
  end

  defp send_sms(phone_number, code) do
    case Application.get_env(:offtherecord, :sms_provider, :test) do
      :twilio -> send_twilio_sms(phone_number, code)
      :test -> send_test_sms(phone_number, code)
      _ -> {:error, "SMS 제공업체가 설정되지 않았습니다."}
    end
  end

  defp send_twilio_sms(phone_number, code) do
    message = "Off The Record 인증 코드: #{code} (5분 내 입력해주세요)"

    try do
      case ExTwilio.Message.create(%{
             to: phone_number,
             from: System.get_env("TWILIO_PHONE_NUMBER"),
             body: message
           }) do
        {:ok, twilio_message} ->
          Logger.info("SMS 발송 성공: #{phone_number} (Message SID: #{twilio_message.sid})")
          {:ok, "인증 코드가 발송되었습니다."}

        {:error, error} ->
          Logger.error("Twilio SMS 발송 실패: #{inspect(error)}")
          {:error, "SMS 발송에 실패했습니다."}
      end
    rescue
      error ->
        Logger.error("Twilio SMS 발송 중 예외 발생: #{inspect(error)}")
        {:error, "SMS 발송에 실패했습니다."}
    end
  end

  defp send_test_sms(phone_number, code) do
    Logger.info("🔔 [TEST SMS] #{phone_number}로 인증 코드 발송: #{code}")
    {:ok, "테스트 모드: 터미널에서 인증 코드를 확인하세요."}
  end
end
