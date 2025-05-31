defmodule OfftherecordWeb.SmsAuthLive do
  use OfftherecordWeb, :live_view
  require Ash.Query
  alias Offtherecord.SMS
  alias Offtherecord.Accounts.User
  alias Offtherecord.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, :phone_input)
     |> assign(:phone_number, "")
     |> assign(:verification_code, "")
     |> assign(:message, nil)
     |> assign(:error, nil)
     |> assign(:loading, false)
     |> assign(:countdown, 0)}
  end

  @impl true
  def handle_event("send_code", %{"phone_number" => phone_number}, socket) do
    phone_number = normalize_phone_number(phone_number)

    if valid_phone_number?(phone_number) do
      socket = assign(socket, :loading, true)

      case SMS.send_verification_code(phone_number) do
        {:ok, message} ->
          {:noreply,
           socket
           |> assign(:step, :code_input)
           |> assign(:phone_number, phone_number)
           |> assign(:message, message)
           |> assign(:error, nil)
           |> assign(:loading, false)
           # 5분 카운트다운
           |> assign(:countdown, 300)
           |> start_countdown()}

        {:error, error} ->
          {:noreply,
           socket
           |> assign(:error, error)
           |> assign(:loading, false)}
      end
    else
      {:noreply,
       socket
       |> assign(:error, "올바른 핸드폰 번호를 입력해주세요. (예: 010-1234-5678)")}
    end
  end

  @impl true
  def handle_event("verify_code", %{"verification_code" => code}, socket) do
    socket = assign(socket, :loading, true)

    case SMS.verify_code(socket.assigns.phone_number, code) do
      {:ok, :verified} ->
        # 사용자 생성 또는 로그인 처리
        case create_or_login_user(socket.assigns.phone_number) do
          {:ok, user} ->
            {:noreply,
             socket
             |> assign(:loading, false)
             |> push_navigate(to: ~p"/auth/sms/success?user_id=#{user.id}")}

          {:error, error} ->
            {:noreply,
             socket
             |> assign(:error, "사용자 생성 중 오류가 발생했습니다: #{inspect(error)}")
             |> assign(:loading, false)}
        end

      {:error, error} ->
        {:noreply,
         socket
         |> assign(:error, error)
         |> assign(:loading, false)}
    end
  end

  @impl true
  def handle_event("resend_code", _params, socket) do
    case SMS.send_verification_code(socket.assigns.phone_number) do
      {:ok, message} ->
        {:noreply,
         socket
         |> assign(:message, message)
         |> assign(:error, nil)
         |> assign(:countdown, 300)
         |> start_countdown()}

      {:error, error} ->
        {:noreply,
         socket
         |> assign(:error, error)}
    end
  end

  @impl true
  def handle_event("back_to_phone", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :phone_input)
     |> assign(:verification_code, "")
     |> assign(:message, nil)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_info(:countdown_tick, socket) do
    if socket.assigns.countdown > 0 do
      Process.send_after(self(), :countdown_tick, 1000)
      {:noreply, assign(socket, :countdown, socket.assigns.countdown - 1)}
    else
      {:noreply, assign(socket, :countdown, 0)}
    end
  end

  # Private functions

  defp normalize_phone_number(phone) do
    phone
    |> String.replace(~r/[^\d]/, "")
    |> case do
      "0" <> rest -> "+82" <> rest
      phone -> phone
    end
  end

  defp valid_phone_number?(phone) do
    String.match?(phone, ~r/^\+82\d{9,10}$/) or String.match?(phone, ~r/^010\d{8}$/)
  end

  defp create_or_login_user(phone_number) do
    case User
         |> Ash.Query.filter(phone_number == phone_number)
         |> Ash.read_one(domain: Accounts) do
      {:ok, user} when not is_nil(user) ->
        {:ok, user}

      _ ->
        User
        |> Ash.Changeset.for_create(:register_with_phone, %{phone_number: phone_number})
        |> Ash.create(domain: Accounts)
    end
  end

  defp start_countdown(socket) do
    Process.send_after(self(), :countdown_tick, 1000)
    socket
  end

  defp format_countdown(seconds) do
    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)
    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{seconds}", 2, "0")}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <!-- Animated background elements -->
      <div class="absolute inset-0 overflow-hidden">
        <div class="absolute -top-40 -left-40 w-80 h-80 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob">
        </div>
        <div class="absolute -top-40 -right-40 w-80 h-80 bg-yellow-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-2000">
        </div>
        <div class="absolute -bottom-40 left-20 w-80 h-80 bg-pink-500 rounded-full mix-blend-multiply filter blur-xl opacity-70 animate-blob animation-delay-4000">
        </div>
      </div>

      <div class="relative z-10 max-w-md w-full space-y-8 p-8">
        <!-- Glass morphism card -->
        <div class="backdrop-blur-xl bg-white/10 border border-white/20 rounded-2xl p-8 shadow-2xl">
          <!-- Logo or brand -->
          <div class="text-center mb-8">
            <div class="mx-auto h-16 w-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mb-4">
              <svg class="h-8 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
                />
              </svg>
            </div>
            <h2 class="text-3xl font-bold text-white">
              {if @step == :phone_input, do: "핸드폰 인증", else: "인증 코드 입력"}
            </h2>
            <p class="mt-2 text-sm text-gray-300">
              {if @step == :phone_input, do: "핸드폰 번호로 간편하게 로그인하세요", else: "SMS로 받은 인증 코드를 입력해주세요"}
            </p>
          </div>
          
    <!-- Messages -->
          <%= if @message do %>
            <div class="mb-4 p-3 bg-green-500/20 border border-green-500/30 rounded-lg">
              <p class="text-green-300 text-sm">{@message}</p>
            </div>
          <% end %>

          <%= if @error do %>
            <div class="mb-4 p-3 bg-red-500/20 border border-red-500/30 rounded-lg">
              <p class="text-red-300 text-sm">{@error}</p>
            </div>
          <% end %>
          
    <!-- Phone Input Step -->
          <%= if @step == :phone_input do %>
            <form id="phone-form" phx-submit="send_code" class="space-y-4">
              <div>
                <label class="block text-white/70 text-sm font-medium mb-2">핸드폰 번호</label>
                <input
                  type="tel"
                  name="phone_number"
                  value={@phone_number}
                  placeholder="010-1234-5678"
                  required
                  class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent backdrop-blur-sm"
                />
              </div>

              <button
                type="submit"
                disabled={@loading}
                class="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white py-3 px-6 rounded-lg font-medium hover:shadow-lg transform hover:scale-105 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
              >
                {if @loading, do: "발송 중...", else: "인증 코드 받기"}
              </button>
            </form>
          <% end %>
          
    <!-- Code Input Step -->
          <%= if @step == :code_input do %>
            <div class="space-y-4">
              <div class="text-center">
                <p class="text-white/70 text-sm mb-4">
                  {@phone_number}로 인증 코드를 발송했습니다
                </p>
                <%= if @countdown > 0 do %>
                  <p class="text-purple-300 text-sm">
                    남은 시간: {format_countdown(@countdown)}
                  </p>
                <% end %>
              </div>

              <form id="code-form" phx-submit="verify_code" class="space-y-4">
                <div>
                  <label class="block text-white/70 text-sm font-medium mb-2">인증 코드</label>
                  <input
                    type="text"
                    name="verification_code"
                    value={@verification_code}
                    placeholder="6자리 숫자"
                    maxlength="6"
                    required
                    class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent backdrop-blur-sm text-center text-2xl tracking-widest"
                  />
                </div>

                <button
                  type="submit"
                  disabled={@loading}
                  class="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white py-3 px-6 rounded-lg font-medium hover:shadow-lg transform hover:scale-105 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                >
                  {if @loading, do: "인증 중...", else: "인증하기"}
                </button>
              </form>

              <div class="flex space-x-3">
                <button
                  phx-click="resend_code"
                  disabled={@countdown > 240}
                  class="flex-1 bg-white/10 text-white py-2 px-4 rounded-lg text-sm hover:bg-white/20 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  재발송
                </button>
                <button
                  phx-click="back_to_phone"
                  class="flex-1 bg-white/10 text-white py-2 px-4 rounded-lg text-sm hover:bg-white/20 transition-all duration-200"
                >
                  번호 변경
                </button>
              </div>
            </div>
          <% end %>
          
    <!-- Back to social login -->
          <div class="mt-6 text-center">
            <a
              href={~p"/login"}
              class="text-purple-300 hover:text-purple-200 text-sm transition-colors"
            >
              ← 소셜 로그인으로 돌아가기
            </a>
          </div>
        </div>
      </div>
    </div>

    <style>
      @keyframes blob {
        0% {
          transform: translate(0px, 0px) scale(1);
        }
        33% {
          transform: translate(30px, -50px) scale(1.1);
        }
        66% {
          transform: translate(-20px, 20px) scale(0.9);
        }
        100% {
          transform: translate(0px, 0px) scale(1);
        }
      }

      .animate-blob {
        animation: blob 7s infinite;
      }

      .animation-delay-2000 {
        animation-delay: 2s;
      }

      .animation-delay-4000 {
        animation-delay: 4s;
      }
    </style>
    """
  end
end
