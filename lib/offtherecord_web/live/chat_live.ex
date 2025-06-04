defmodule OfftherecordWeb.ChatLive do
  use OfftherecordWeb, :live_view

  on_mount {OfftherecordWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:posts, [])
     |> assign(:loading, false)
     |> assign(:messages, [
       %{role: "assistant", content: "안녕하세요! 감정이나 기억에 대해 질문해보세요. 예: '우울했던 날은 언제였나요?'"}
     ])}
  end

  @impl true
  def handle_event("chat", %{"query" => query}, socket) do
    if String.trim(query) != "" do
      send(self(), {:perform_chat, query})

      {:noreply,
       socket
       |> assign(:loading, true)
       |> assign(:query, query)
       |> add_message("user", query)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply,
     socket
     |> assign(:query, "")
     |> assign(:posts, [])
     |> assign(:messages, [
       %{role: "assistant", content: "새로운 대화를 시작합니다. 어떤 감정이나 기억을 찾고 싶으신가요?"}
     ])}
  end

  @impl true
  def handle_info({:perform_chat, query}, socket) do
    user = socket.assigns[:current_user]

    if user do
      case search_posts(query, user) do
        {:ok, posts} ->
          response_message = generate_response_message(query, posts)

          {:noreply,
           socket
           |> assign(:posts, posts)
           |> assign(:loading, false)
           |> add_message("assistant", response_message)}

        {:error, _error} ->
          {:noreply,
           socket
           |> assign(:posts, [])
           |> assign(:loading, false)
           |> add_message("assistant", "죄송합니다. 검색 중 오류가 발생했습니다.")}
      end
    else
      {:noreply,
       socket
       |> assign(:loading, false)
       |> add_message("assistant", "로그인이 필요합니다.")}
    end
  end

  defp search_posts(query, user) do
    user_id = Ecto.UUID.dump!(user.id)
    min_similarity = 30.0
    # 0.7
    max_distance = (100.0 - min_similarity) / 100.0

    case Offtherecord.Ai.OpenAiEmbeddingModel.generate([query], []) do
      {:ok, [search_vector]} ->
        result =
          Ecto.Adapters.SQL.query!(
            Offtherecord.Repo,
            """
            SELECT id, content, date, 
                   (full_text_vector <=> $1) as distance
            FROM posts 
            WHERE full_text_vector IS NOT NULL
              AND user_id = $2
              AND (full_text_vector <=> $1) <= $3
            ORDER BY full_text_vector <=> $1
            LIMIT 10
            """,
            [search_vector, user_id, max_distance]
          )

        posts =
          Enum.map(result.rows, fn [id, content, date, distance] ->
            %{
              id: Ecto.UUID.cast!(id),
              content: content,
              date: date,
              similarity: Float.round((1.0 - distance) * 100, 1)
            }
          end)

        {:ok, posts}

      {:error, error} ->
        {:error, error}
    end
  end

  defp generate_response_message(query, posts) do
    case length(posts) do
      0 ->
        "\"#{query}\"에 대한 관련 기록을 찾지 못했습니다. (유사도 30% 이상 기준)"

      count ->
        similarity_avg =
          posts
          |> Enum.map(& &1.similarity)
          |> Enum.sum()
          |> Kernel./(count)
          |> Float.round(1)

        confidence_level =
          cond do
            similarity_avg >= 80 -> "매우 높은"
            similarity_avg >= 60 -> "높은"
            similarity_avg >= 40 -> "보통"
            true -> "낮은"
          end

        "\"#{query}\"와 관련된 #{count}개의 기록을 찾았습니다. (평균 유사도: #{similarity_avg}%, #{confidence_level} 신뢰도)"
    end
  end

  defp add_message(socket, role, content) do
    new_message = %{role: role, content: content}
    messages = socket.assigns.messages ++ [new_message]
    assign(socket, :messages, messages)
  end

  defp format_date(date) do
    case date do
      %Date{} = date ->
        Calendar.strftime(date, "%Y년 %m월 %d일")

      %DateTime{} = datetime ->
        datetime
        |> DateTime.to_date()
        |> Calendar.strftime("%Y년 %m월 %d일")

      %NaiveDateTime{} = naive_datetime ->
        naive_datetime
        |> NaiveDateTime.to_date()
        |> Calendar.strftime("%Y년 %m월 %d일")

      _ ->
        "알 수 없음"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- 헤더 -->
      <div class="bg-white shadow-sm border-b">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center py-4">
            <div class="flex items-center space-x-4">
              <h1 class="text-2xl font-bold text-gray-900">감정 기록 채팅</h1>
              <span class="text-sm text-gray-500">AI 기반 의미 검색</span>
            </div>
            <div class="flex items-center space-x-4">
              <.link navigate="/" class="text-blue-600 hover:text-blue-800">
                ← 메인으로
              </.link>
              <button
                phx-click="clear"
                class="px-3 py-1 text-sm bg-gray-100 text-gray-700 rounded hover:bg-gray-200"
              >
                초기화
              </button>
            </div>
          </div>
        </div>
      </div>
      
    <!-- 메인 컨텐츠 -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 h-[calc(100vh-180px)]">
          
    <!-- 왼쪽: 검색 결과 (포스트들) -->
          <div class="bg-white rounded-lg shadow-sm border">
            <div class="p-4 border-b bg-gray-50 rounded-t-lg">
              <h2 class="text-lg font-semibold text-gray-900">관련 기록</h2>
              <p class="text-sm text-gray-600">질문과 관련된 기록들이 여기에 표시됩니다</p>
            </div>

            <div class="h-full overflow-y-auto p-4 space-y-4">
              <%= if @loading do %>
                <div class="flex items-center justify-center py-12">
                  <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  <span class="ml-3 text-gray-600">찾는 중...</span>
                </div>
              <% else %>
                <%= if length(@posts) > 0 do %>
                  <%= for post <- @posts do %>
                    <div class="border rounded-lg p-4 hover:bg-gray-50">
                      <div class="flex justify-between items-start mb-2">
                        <span class="text-xs text-green-600 font-medium">
                          유사도: {post.similarity}%
                        </span>
                        <span class="text-xs text-gray-500">
                          {format_date(post.date)}
                        </span>
                      </div>
                      <p class="text-gray-800 leading-relaxed">
                        {post.content}
                      </p>
                    </div>
                  <% end %>
                <% else %>
                  <div class="text-center py-12 text-gray-500">
                    <svg
                      class="mx-auto h-12 w-12 text-gray-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.013 8.013 0 01-7-4c0-4.418 3.582-8 8-8s8 3.582 8 8z"
                      />
                    </svg>
                    <p class="mt-2">오른쪽에서 질문을 입력해보세요</p>
                    <p class="text-sm">예: "우울했던 날은 언제였나요?"</p>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
          
    <!-- 오른쪽: 채팅 인터페이스 -->
          <div class="bg-white rounded-lg shadow-sm border flex flex-col">
            <div class="p-4 border-b bg-blue-50 rounded-t-lg">
              <h2 class="text-lg font-semibold text-gray-900">AI 채팅 도우미</h2>
              <p class="text-sm text-gray-600">자연어로 감정이나 기억에 대해 질문해보세요</p>
            </div>
            
    <!-- 채팅 메시지들 -->
            <div class="flex-1 overflow-y-auto p-4 space-y-4">
              <%= for message <- @messages do %>
                <div class={[
                  "flex",
                  if(message.role == "user", do: "justify-end", else: "justify-start")
                ]}>
                  <div class={[
                    "max-w-xs lg:max-w-md px-4 py-2 rounded-lg",
                    if(message.role == "user",
                      do: "bg-blue-600 text-white",
                      else: "bg-gray-100 text-gray-800"
                    )
                  ]}>
                    <%= if message.role == "assistant" do %>
                      <div class="flex items-center mb-1">
                        <div class="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                        <span class="text-xs font-medium">AI 도우미</span>
                      </div>
                    <% end %>
                    <p class="text-sm">{message.content}</p>
                  </div>
                </div>
              <% end %>

              <%= if @loading do %>
                <div class="flex justify-start">
                  <div class="bg-gray-100 text-gray-800 max-w-xs lg:max-w-md px-4 py-2 rounded-lg">
                    <div class="flex items-center">
                      <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-600 mr-2">
                      </div>
                      <span class="text-sm">생각하는 중...</span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
            
    <!-- 입력 폼 -->
            <div class="p-4 border-t bg-gray-50">
              <form phx-submit="chat" class="flex space-x-2">
                <input
                  type="text"
                  name="query"
                  value={@query}
                  placeholder="예: 우울했던 날은 언제였나요?"
                  class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  disabled={@loading}
                />
                <button
                  type="submit"
                  disabled={@loading}
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <%= if @loading do %>
                    <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <% else %>
                    전송
                  <% end %>
                </button>
              </form>

              <div class="mt-2 text-xs text-gray-500">
                <p>💬 팁: "행복했던 순간", "화가 났던 일", "슬펐던 기억" 등으로 대화해보세요</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
