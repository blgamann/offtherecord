defmodule OfftherecordWeb.Components.Posts do
  @moduledoc """
  Post-related components for the Off the Record application.
  """
  use OfftherecordWeb, :verified_routes
  use Phoenix.Component
  import OfftherecordWeb.Components.UI

  @doc """
  Renders a form for creating new posts.
  """
  attr :form, :map, required: true
  attr :uploading, :boolean, default: false
  attr :uploaded_image_url, :string, default: nil
  attr :preview_image_url, :string, default: nil
  attr :selected_file_info, :map, default: nil
  attr :upload_error, :string, default: nil

  def post_form(assigns) do
    ~H"""
    <.card class="p-8 mb-10">
      <form phx-submit="create_post" phx-change="validate_post" class="space-y-6" novalidate>
        <div>
          <textarea
            name="content"
            placeholder="오늘 어떤 일이 있었나요? 자유롭게 기록해보세요..."
            class="w-full border-none outline-none text-lg leading-relaxed bg-transparent resize-none placeholder:text-slate-400 min-h-[120px] focus:ring-0"
          ><%= @form[:content].value %></textarea>
        </div>

    <!-- Upload Error Display -->
        <%= if @upload_error do %>
          <div class="rounded-md bg-red-50 p-4 mb-4">
            <div class="flex items-center">
              <svg class="h-5 w-5 text-red-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
              <p class="text-sm text-red-800">{@upload_error}</p>
              <button
                type="button"
                phx-click="reset_upload"
                class="ml-auto text-red-600 hover:text-red-800 text-sm underline"
              >
                재시도
              </button>
            </div>
          </div>
        <% end %>

    <!-- Image Upload Section -->
        <div class="border-t border-slate-200 pt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-medium text-slate-700">이미지 첨부</h3>
            <%= if @uploading do %>
              <span class="text-sm text-blue-600 flex items-center">
                <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600 mr-2"></div>
                업로드 중...
              </span>
            <% end %>
          </div>

    <!-- Uploading State -->
          <%= if @uploading and @selected_file_info do %>
            <div class="mb-4">
              <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div class="flex items-center">
                  <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mr-4">
                  </div>
                  <div class="flex-1">
                    <h4 class="text-sm font-medium text-blue-900">업로드 중...</h4>
                    <p class="text-sm text-blue-700">{@selected_file_info.name}</p>
                    <p class="text-xs text-blue-600">
                      크기: {format_file_size(@selected_file_info.size)}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

    <!-- Image Preview -->
          <%= if @preview_image_url || @uploaded_image_url do %>
            <div class="mb-4">
              <div class="relative inline-block">
                <img
                  src={@uploaded_image_url || @preview_image_url}
                  alt="이미지 미리보기"
                  class="max-w-md rounded-lg shadow-sm max-h-64 object-cover"
                />

    <!-- Upload overlay -->
                <%= if @uploading do %>
                  <div class="absolute inset-0 bg-black bg-opacity-50 rounded-lg flex items-center justify-center">
                    <div class="text-center text-white">
                      <div class="animate-spin rounded-full h-8 w-8 border-2 border-white border-t-transparent mx-auto mb-2">
                      </div>
                      <p class="text-sm font-medium">업로드 중...</p>
                      <%= if @selected_file_info do %>
                        <p class="text-xs opacity-80">{@selected_file_info.name}</p>
                      <% end %>
                    </div>
                  </div>
                <% end %>

    <!-- Remove button -->
                <%= if @uploaded_image_url && !@uploading do %>
                  <button
                    type="button"
                    phx-click="remove_uploaded_image"
                    class="absolute top-2 right-2 bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors"
                    title="이미지 제거"
                  >
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                <% end %>
              </div>

    <!-- Status message -->
              <%= if @uploaded_image_url && !@uploading do %>
                <p class="text-sm text-green-600 mt-2">✓ 이미지가 준비되었습니다</p>
              <% else %>
                <%= if @uploading do %>
                  <p class="text-sm text-blue-600 mt-2 flex items-center">
                    <div class="animate-pulse w-2 h-2 bg-blue-600 rounded-full mr-2"></div>
                    Cloudflare에 업로드 중...
                  </p>
                <% end %>
              <% end %>
            </div>
          <% end %>

    <!-- File Upload Input -->
          <%= if !@preview_image_url && !@uploaded_image_url && !@upload_error do %>
            <div class="space-y-4">
              <div class="border-2 border-dashed border-slate-300 rounded-lg p-6 text-center hover:border-slate-400 transition-colors">
                <svg
                  class="mx-auto h-12 w-12 text-slate-400"
                  stroke="currentColor"
                  fill="none"
                  viewBox="0 0 48 48"
                >
                  <path
                    d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </svg>
                <div class="mt-4">
                  <label for="manual-file-input" class="cursor-pointer">
                    <span class="mt-2 block text-sm font-medium text-slate-900">
                      이미지를 클릭하여 선택하세요
                    </span>
                    <span class="mt-1 block text-xs text-slate-500">
                      PNG, JPG, GIF 최대 10MB
                    </span>
                  </label>
                  <input
                    type="file"
                    id="manual-file-input"
                    accept=".jpg,.jpeg,.png,.gif,.webp"
                    class="sr-only"
                    phx-hook="ManualFileUpload"
                  />
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <input type="hidden" name="image_url" value={@uploaded_image_url || ""} />
        <div class="flex justify-end">
          <.gradient_button type="submit" disabled={@uploading}>
            <%= if @uploading do %>
              이미지 업로드 중...
            <% else %>
              기록 추가
            <% end %>
          </.gradient_button>
        </div>
      </form>
    </.card>
    """
  end

  @doc """
  Renders the posts timeline with date grouping.
  """
  attr :posts, :list, required: true
  attr :modal_image_url, :string, default: nil
  attr :show_modal, :boolean, default: false

  def posts_timeline(assigns) do
    ~H"""
    <div class="space-y-12">
      <%= if length(@posts) == 0 do %>
        <.empty_state
          icon="📝"
          title="아직 기록이 없습니다"
          description="첫 번째 기록을 작성해보세요!"
        />
      <% else %>
        <%= for {date, date_posts} <- group_posts_by_date(@posts) do %>
          <.date_group date={date} posts={date_posts} />
        <% end %>
      <% end %>

      <.image_modal image_url={@modal_image_url || ""} show={@show_modal} />
    </div>
    """
  end

  @doc """
  Renders a group of posts for a specific date.
  """
  attr :date, :string, required: true
  attr :posts, :list, required: true

  def date_group(assigns) do
    ~H"""
    <div class="space-y-6">
      <.date_header date={@date} count={length(@posts)} />
      <.posts_grid posts={@posts} />
    </div>
    """
  end

  @doc """
  Renders the date header with post count.
  """
  attr :date, :string, required: true
  attr :count, :integer, required: true

  def date_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <.badge>
        {@date}
      </.badge>
      <div class="text-slate-500 text-sm font-medium">
        {@count}개의 기록
      </div>
    </div>
    """
  end

  @doc """
  Renders a horizontal scrollable grid of post cards.
  """
  attr :posts, :list, required: true

  def posts_grid(assigns) do
    ~H"""
    <div
      id="horizontal-scroll-container"
      class="horizontal-scroll-container overflow-x-auto"
      phx-hook="HorizontalScroll"
    >
      <div class="flex gap-5 pb-4" style="width: max-content;">
        <%= for post <- @posts do %>
          <div class="flex-none w-80 md:w-80 sm:w-72">
            <.post_card post={post} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an individual post card.
  """
  attr :post, :map, required: true

  def post_card(assigns) do
    ~H"""
    <div class="flex flex-col space-y-1">
      <div class="group relative bg-slate-50 border border-slate-200 overflow-hidden hover:shadow-lg transition-all duration-300 min-h-[100px] flex">
        <.post_sidebar number={generate_record_number(@post.id)} />
        <.post_content post={@post} />
      </div>
      <.post_time time={format_date(@post.created_at)} />
    </div>
    """
  end

  @doc """
  Renders the sidebar with record number.
  """
  attr :number, :string, required: true

  def post_sidebar(assigns) do
    ~H"""
    <div class="bg-slate-800 w-10 flex items-center justify-center">
      <span class="text-white text-xs font-medium transform rotate-90">
        {@number}
      </span>
    </div>
    """
  end

  @doc """
  Renders the main content area of a post.
  """
  attr :post, :map, required: true

  def post_content(assigns) do
    ~H"""
    <div class="flex-1 p-4 pt-3 bg-white flex flex-col">
      <%= if @post.image_url && @post.image_url != "" do %>
        <div class="mb-2">
          <img
            src={@post.image_url}
            alt="포스트 이미지"
            class="w-full h-32 object-cover rounded cursor-pointer hover:opacity-90 transition-opacity"
            phx-click="show_image_modal"
            phx-value-image-url={@post.image_url}
          />
        </div>
      <% end %>

      <div
        class="text-slate-800 text-sm leading-relaxed"
        phx-hook="FixWhitespace"
        id={"post-content-#{@post.id}"}
      >
        {format_post_content(@post.content)}
      </div>
    </div>
    """
  end

  @doc """
  Renders the post timestamp.
  """
  attr :time, :string, required: true

  def post_time(assigns) do
    ~H"""
    <div class="text-right text-slate-400 text-xs pr-2">
      {@time}
    </div>
    """
  end

  @doc """
  Renders a delete button for posts.
  """
  attr :post_id, :string, required: true

  def delete_button(assigns) do
    ~H"""
    <button
      phx-click="delete_post"
      phx-value-id={@post_id}
      data-confirm="이 기록을 삭제하시겠습니까?"
      class="absolute top-2.5 right-2.5 w-6 h-6 bg-red-500 hover:bg-red-600 text-white rounded-full text-xs opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center justify-center"
    >
      ×
    </button>
    """
  end

  @doc """
  Renders an image modal for viewing full-size images.
  """
  attr :image_url, :string, required: true
  attr :show, :boolean, default: false

  def image_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        id="image-modal"
        class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4"
        phx-click="hide_image_modal"
        phx-hook="ImageModal"
      >
        <div class="relative max-w-4xl max-h-full">
          <button
            phx-click="hide_image_modal"
            class="absolute top-4 right-4 text-white bg-black bg-opacity-50 rounded-full p-2 hover:bg-opacity-75 transition-all z-10"
          >
            <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
          <img
            src={@image_url}
            alt="원본 이미지"
            class="max-w-full max-h-full object-contain rounded"
            phx-click-away="hide_image_modal"
          />
        </div>
      </div>
    <% end %>
    """
  end

  # Helper functions
  defp group_posts_by_date(posts) do
    posts
    |> Enum.group_by(&format_date_full(&1.created_at))
    |> Enum.sort_by(
      fn {_date, date_posts} ->
        hd(date_posts).created_at
      end,
      {:desc, DateTime}
    )
  end

  defp format_date_full(date) do
    case DateTime.shift_zone(date, "Asia/Seoul") do
      {:ok, shifted_date} ->
        year = shifted_date.year
        month = shifted_date.month
        day = shifted_date.day
        "#{year}년 #{month}월 #{day}일"

      {:error, _} ->
        seconds_since_epoch = DateTime.to_unix(date)
        seoul_seconds = seconds_since_epoch + 9 * 60 * 60
        shifted_date = DateTime.from_unix!(seoul_seconds)

        year = shifted_date.year
        month = shifted_date.month
        day = shifted_date.day
        "#{year}년 #{month}월 #{day}일"
    end
  end

  defp format_date(date) do
    case DateTime.shift_zone(date, "Asia/Seoul") do
      {:ok, shifted_date} ->
        shifted_date
        |> DateTime.to_time()
        |> Time.to_string()
        |> String.slice(0, 5)

      {:error, _} ->
        seconds_since_epoch = DateTime.to_unix(date)
        seoul_seconds = seconds_since_epoch + 9 * 60 * 60

        DateTime.from_unix!(seoul_seconds)
        |> DateTime.to_time()
        |> Time.to_string()
        |> String.slice(0, 5)
    end
  end

  defp generate_record_number(post_id) do
    :crypto.hash(:md5, post_id)
    |> :binary.decode_unsigned()
    |> rem(1000)
    |> Integer.to_string()
    |> String.pad_leading(3, "0")
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_file_size(bytes), do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  # whitespace-pre-line 문제 완전 해결 - HTML 직접 생성
  defp format_post_content(content) when is_binary(content) do
    content
    # 앞뒤 공백 제거
    |> String.trim()
    # 개행 통일
    |> String.replace(~r/\r\n|\r/, "\n")
    # 줄별로 분리
    |> String.split("\n")
    # 각 줄을 안전하게 이스케이프하고 문자열로 변환
    |> Enum.map(fn line ->
      line
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()
    end)
    # <br>로 연결
    |> Enum.join("<br>")
    # raw HTML로 반환
    |> Phoenix.HTML.raw()
  end

  defp format_post_content(_), do: ""
end
