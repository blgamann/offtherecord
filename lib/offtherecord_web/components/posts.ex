defmodule OfftherecordWeb.Components.Posts do
  @moduledoc """
  Post-related components for the Off the Record application.
  Designed with Medium-inspired clean aesthetics with subtle confidential touches.
  """
  use OfftherecordWeb, :verified_routes
  use Phoenix.Component
  import OfftherecordWeb.Components.UI
  alias Phoenix.LiveView.JS

  @doc """
  Renders a Facebook-style compose button that opens a modal.
  """
  attr :current_user, :map, required: true

  def compose_button(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto mb-6">
      <.clean_card class="p-4">
        <button
          phx-click="open_compose_modal"
          class="w-full flex items-center space-x-3 p-3 text-left bg-gray-50 hover:bg-gray-100 rounded-full border border-gray-200 transition-colors duration-200"
        >
          <.user_avatar user={@current_user} size="w-10 h-10" />
          <span class="text-gray-500 text-lg">
            {@current_user.name || @current_user.email}님, 무슨 생각을 하고 계신가요?
          </span>
        </button>
      </.clean_card>
    </div>
    """
  end

  @doc """
  Renders a modal for composing new posts.
  """
  attr :show, :boolean, required: true
  attr :form, :map, required: true
  attr :uploading, :boolean, default: false
  attr :uploaded_image_url, :string, default: nil
  attr :preview_image_url, :string, default: nil
  attr :selected_file_info, :map, default: nil
  attr :upload_error, :string, default: nil
  attr :current_user, :map, required: true

  def compose_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        id="compose-modal"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
        phx-click-away="close_compose_modal"
      >
        <div
          class="bg-white rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto"
          phx-click-away="ignore"
        >
          <!-- Modal Header -->
          <div class="flex items-center justify-between p-4 border-b border-gray-200">
            <h2 class="text-lg font-semibold text-gray-900">포스트 작성</h2>
            <button
              phx-click="close_compose_modal"
              class="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
          
    <!-- Modal Content -->
          <form phx-submit="create_post" phx-change="validate_post" class="p-4 space-y-4" novalidate>
            <!-- User info -->
            <div class="flex items-center space-x-3">
              <.user_avatar user={@current_user} size="w-10 h-10" />
              <span class="font-medium text-gray-900">
                {@current_user.name || @current_user.email}
              </span>
            </div>
            
    <!-- Content textarea -->
            <div>
              <textarea
                name="content"
                placeholder="무슨 생각을 하고 계신가요?"
                class="w-full bg-white border-0 focus:ring-0 focus:outline-none resize-none text-gray-900 placeholder:text-gray-500 text-lg leading-relaxed min-h-[120px]"
                autofocus
              ><%= @form[:content].value %></textarea>
            </div>
            
    <!-- Upload Error Display -->
            <%= if @upload_error do %>
              <div class="bg-red-50 border border-red-200 rounded-lg p-3">
                <div class="flex items-center">
                  <svg class="w-5 h-5 text-red-400 mr-3" fill="currentColor" viewBox="0 0 20 20">
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
                    class="ml-auto text-red-600 hover:text-red-800 text-sm font-medium"
                  >
                    다시 시도
                  </button>
                </div>
              </div>
            <% end %>
            
    <!-- Image Preview -->
            <%= if @preview_image_url || @uploaded_image_url do %>
              <div class="relative">
                <img
                  src={@uploaded_image_url || @preview_image_url}
                  alt="Upload preview"
                  class="w-full max-h-80 object-cover rounded-lg"
                />
                
    <!-- Upload overlay -->
                <%= if @uploading do %>
                  <div class="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center rounded-lg">
                    <div class="text-center text-white">
                      <div class="animate-spin rounded-full h-8 w-8 border-2 border-white border-t-transparent mx-auto mb-2">
                      </div>
                      <p class="text-sm font-medium">업로드 중...</p>
                    </div>
                  </div>
                <% end %>
                
    <!-- Remove button -->
                <%= if @uploaded_image_url && !@uploading do %>
                  <button
                    type="button"
                    phx-click="remove_uploaded_image"
                    class="absolute top-2 right-2 bg-gray-900 bg-opacity-80 text-white rounded-full p-2 hover:bg-opacity-100 transition-opacity"
                    title="이미지 제거"
                  >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
            <% end %>
            
    <!-- Action buttons bar -->
            <div class="flex items-center justify-between pt-3 border-t border-gray-200">
              <div class="flex items-center space-x-4">
                <!-- Photo upload button -->
                <%= if !@preview_image_url && !@uploaded_image_url && !@upload_error do %>
                  <label
                    for="modal-file-input"
                    class="cursor-pointer flex items-center space-x-2 text-gray-600 hover:text-gray-800 transition-colors"
                  >
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                      />
                    </svg>
                    <span class="text-sm font-medium">사진</span>
                  </label>
                  <input
                    type="file"
                    id="modal-file-input"
                    accept=".jpg,.jpeg,.png,.gif,.webp"
                    class="sr-only"
                    phx-hook="ManualFileUpload"
                  />
                <% end %>
              </div>
              
    <!-- Submit button -->
              <input type="hidden" name="image_url" value={@uploaded_image_url || ""} />
              <button
                type="submit"
                disabled={@uploading}
                class={[
                  "relative overflow-hidden transition-all duration-200 font-medium",
                  if(@uploading,
                    do: "bg-gray-300 text-gray-500 cursor-not-allowed",
                    else: "bg-gray-900 hover:bg-gray-800 text-white hover:shadow-md active:scale-95"
                  ),
                  "px-4 py-2 rounded-lg text-sm"
                ]}
              >
                <span class="relative z-10">
                  <%= if @uploading do %>
                    게시 중...
                  <% else %>
                    게시
                  <% end %>
                </span>
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  attr :form, :map, required: true
  attr :uploading, :boolean, default: false
  attr :uploaded_image_url, :string, default: nil
  attr :preview_image_url, :string, default: nil
  attr :selected_file_info, :map, default: nil
  attr :upload_error, :string, default: nil

  def post_form(assigns) do
    ~H"""
    <.clean_card class="p-8 mb-12 max-w-3xl mx-auto">
      <form phx-submit="create_post" phx-change="validate_post" class="space-y-6" novalidate>
        <!-- Content field -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-3">
            What's on your mind?
          </label>

          <textarea
            name="content"
            placeholder="Share your thoughts, experiences, or ideas..."
            class="w-full bg-white border border-gray-200 rounded-lg p-4 text-gray-900 placeholder:text-gray-500 focus:border-gray-400 focus:ring-0 focus:outline-none resize-none transition-colors duration-200 text-lg leading-relaxed min-h-[160px]"
          ><%= @form[:content].value %></textarea>
        </div>
        
    <!-- Upload Error Display -->
        <%= if @upload_error do %>
          <div class="bg-red-50 border border-red-200 rounded-lg p-4">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-red-400 mr-3" fill="currentColor" viewBox="0 0 20 20">
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
                class="ml-auto text-red-600 hover:text-red-800 text-sm font-medium"
              >
                Try again
              </button>
            </div>
          </div>
        <% end %>
        
    <!-- Image Upload Section -->
        <div>
          <.divider class="mb-6" />

          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-medium text-gray-700">Add an image</h3>
            <%= if @uploading do %>
              <div class="flex items-center space-x-2 text-gray-500">
                <div class="animate-spin rounded-full h-4 w-4 border-2 border-gray-400 border-t-transparent">
                </div>
                <span class="text-sm">Uploading...</span>
              </div>
            <% end %>
          </div>
          
    <!-- Image Preview -->
          <%= if @preview_image_url || @uploaded_image_url do %>
            <div class="mb-4">
              <div class="relative inline-block rounded-lg overflow-hidden border border-gray-200">
                <img
                  src={@uploaded_image_url || @preview_image_url}
                  alt="Upload preview"
                  class="max-w-full max-h-80 object-cover"
                />
                
    <!-- Upload overlay -->
                <%= if @uploading do %>
                  <div class="absolute inset-0 bg-black bg-opacity-40 flex items-center justify-center">
                    <div class="text-center text-white">
                      <div class="animate-spin rounded-full h-8 w-8 border-2 border-white border-t-transparent mx-auto mb-2">
                      </div>
                      <p class="text-sm font-medium">Uploading...</p>
                    </div>
                  </div>
                <% end %>
                
    <!-- Remove button -->
                <%= if @uploaded_image_url && !@uploading do %>
                  <button
                    type="button"
                    phx-click="remove_uploaded_image"
                    class="absolute top-2 right-2 bg-gray-900 bg-opacity-80 text-white rounded-full p-2 hover:bg-opacity-100 transition-opacity"
                    title="Remove image"
                  >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                <p class="text-sm text-green-600 mt-2 flex items-center">
                  <.indicator_dot variant="green" class="mr-2" /> Image ready to publish
                </p>
              <% end %>
            </div>
          <% end %>
          
    <!-- File Upload Input -->
          <%= if !@preview_image_url && !@uploaded_image_url && !@upload_error do %>
            <div class="border-2 border-dashed border-gray-200 rounded-lg p-6 text-center hover:border-gray-300 transition-colors">
              <svg
                class="mx-auto h-10 w-10 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2 2v14a2 2 0 002 2z"
                />
              </svg>
              <div class="mt-4">
                <label for="manual-file-input" class="cursor-pointer">
                  <span class="text-sm font-medium text-gray-900">
                    Click to upload an image
                  </span>
                  <span class="block text-xs text-gray-500 mt-1">
                    PNG, JPG, GIF up to 10MB
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
          <% end %>
        </div>
        
    <!-- Submit button -->
        <input type="hidden" name="image_url" value={@uploaded_image_url || ""} />
        <div class="flex justify-end pt-4">
          <.clean_button type="submit" variant="primary" disabled={@uploading}>
            <%= if @uploading do %>
              Publishing...
            <% else %>
              Publish
            <% end %>
          </.clean_button>
        </div>
      </form>
    </.clean_card>
    """
  end

  @doc """
  Renders the posts timeline with clean, Medium-style layout.
  """
  attr :posts, :list, required: true
  attr :modal_image_url, :string, default: nil
  attr :show_modal, :boolean, default: false

  def posts_timeline(assigns) do
    # 시간순으로 정렬해서 넘버링용 인덱스 맵 생성
    posts_with_numbers =
      assigns.posts
      # 오래된 순으로 정렬
      |> Enum.sort_by(& &1.created_at, {:asc, DateTime})
      # 1부터 시작하는 인덱스
      |> Enum.with_index(1)
      |> Enum.into(%{}, fn {post, index} -> {post.id, index} end)

    assigns = assign(assigns, :posts_with_numbers, posts_with_numbers)

    ~H"""
    <div class="space-y-12">
      <%= if length(@posts) == 0 do %>
        <.clean_empty_state
          icon="✍️"
          title="No posts yet"
          description="Start documenting your thoughts and experiences. Your personal archive awaits your first entry."
        />
      <% else %>
        <%= for {date, date_posts} <- group_posts_by_date(@posts) do %>
          <.date_section date={date} posts={date_posts} posts_with_numbers={@posts_with_numbers} />
        <% end %>
      <% end %>

      <.image_modal image_url={@modal_image_url || ""} show={@show_modal} />
    </div>
    """
  end

  @doc """
  Renders a date section with posts.
  """
  attr :date, :string, required: true
  attr :posts, :list, required: true
  attr :posts_with_numbers, :map, required: true

  def date_section(assigns) do
    ~H"""
    <section class="space-y-6">
      <.date_header date={@date} count={length(@posts)} />
      <.posts_grid posts={@posts} posts_with_numbers={@posts_with_numbers} />
    </section>
    """
  end

  @doc """
  Renders the date header with clean typography.
  """
  attr :date, :string, required: true
  attr :count, :integer, required: true

  def date_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <.subtle_badge variant="default">
        {@date}
      </.subtle_badge>
      <span class="text-sm text-gray-500 font-medium">
        {@count} {if @count == 1, do: "entry", else: "entries"}
      </span>
    </div>
    """
  end

  @doc """
  Renders a horizontal scrollable grid of post cards.
  """
  attr :posts, :list, required: true
  attr :posts_with_numbers, :map, required: true

  def posts_grid(assigns) do
    ~H"""
    <div
      id="horizontal-scroll-container"
      class="horizontal-scroll-container overflow-x-auto"
      phx-hook="HorizontalScroll"
    >
      <div class="flex gap-6 pb-4" style="width: max-content;">
        <%= for post <- @posts do %>
          <div class="flex-none w-80 md:w-80 sm:w-72">
            <.story_card post={post} post_number={@posts_with_numbers[post.id]} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an individual story card (keeping your preferred card design but with cleaner styling).
  """
  attr :post, :map, required: true
  attr :post_number, :integer, required: true

  def story_card(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="group relative bg-white border border-gray-200 overflow-hidden hover:shadow-md transition-all duration-200 min-h-[120px] flex rounded-lg">
        <.story_number number={@post_number} />
        <.story_content post={@post} />
      </div>
      <.story_timestamp time={format_date(@post.created_at)} />
    </div>
    """
  end

  @doc """
  Renders the story number tab.
  """
  attr :number, :integer, required: true

  def story_number(assigns) do
    ~H"""
    <div class="bg-gray-800 w-12 flex items-center justify-center rounded-l-lg">
      <span class="text-white text-xs font-medium transform rotate-90 font-mono">
        {String.pad_leading("#{@number}", 3, "0")}
      </span>
    </div>
    """
  end

  @doc """
  Renders the main content area of a story.
  """
  attr :post, :map, required: true

  def story_content(assigns) do
    ~H"""
    <div class="flex-1 p-4 bg-white flex flex-col">
      <!-- Text content -->
      <div
        class="text-gray-800 text-sm leading-relaxed flex-1"
        phx-hook="FixWhitespace"
        id={"post-content-#{@post.id}"}
      >
        {format_post_content(@post.content)}
      </div>
      
    <!-- Image at bottom -->
      <%= if @post.image_url && @post.image_url != "" do %>
        <div class="mt-3">
          <img
            src={@post.image_url}
            alt="Story image"
            class="w-full h-32 object-cover rounded cursor-pointer hover:opacity-95 transition-opacity"
            phx-click="show_image_modal"
            phx-value-image-url={@post.image_url}
          />
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the story timestamp.
  """
  attr :time, :string, required: true

  def story_timestamp(assigns) do
    ~H"""
    <div class="text-right text-gray-400 text-xs pr-2 font-mono">
      {@time}
    </div>
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
            class="absolute top-4 right-4 bg-white bg-opacity-90 text-gray-900 rounded-full p-2 hover:bg-opacity-100 transition-all z-10 shadow-lg"
          >
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
            alt="Full size image"
            class="max-w-full max-h-full object-contain rounded-lg"
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
        shifted_date
        |> Calendar.strftime("%B %d, %Y")

      {:error, _} ->
        seconds_since_epoch = DateTime.to_unix(date)
        seoul_seconds = seconds_since_epoch + 9 * 60 * 60
        shifted_date = DateTime.from_unix!(seoul_seconds)

        shifted_date
        |> Calendar.strftime("%B %d, %Y")
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

  @doc """
  Renders a horizontal scrollable list of category filter buttons.
  """
  attr :categories, :list, default: []
  attr :selected_category_id, :string, default: nil

  def category_horizontal_list(assigns) do
    ~H"""
    <div class="w-full bg-white border-t border-gray-200">
      <div class="max-w-3xl mx-auto px-4 py-3">
        <div class="flex items-center space-x-3 overflow-x-auto scrollbar-hide">
          <!-- 전체 버튼 -->
          <button
            phx-click="select_category"
            phx-value-category-id=""
            class={[
              "flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-colors duration-200",
              if(@selected_category_id == nil,
                do: "bg-blue-600 text-white",
                else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
              )
            ]}
          >
            전체
          </button>
          
    <!-- 기존 카테고리들 -->
          <div :for={category <- @categories} class="flex-shrink-0">
            <button
              phx-click="select_category"
              phx-value-category-id={category.id}
              class={[
                "px-4 py-2 rounded-full text-sm font-medium transition-colors duration-200",
                if(@selected_category_id == category.id,
                  do: "bg-blue-600 text-white",
                  else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
                )
              ]}
            >
              {category.name}
            </button>
          </div>
          
    <!-- 새 카테고리 버튼 -->
          <button
            phx-click="open_create_category_modal"
            class="flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium bg-green-100 text-green-700 hover:bg-green-200 transition-colors duration-200"
          >
            + 새 카테고리
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a modal for selecting or creating categories for a post.
  """
  attr :show, :boolean, required: true
  attr :categories, :list, default: []
  attr :category_form, :map, default: %{}
  attr :pending_post_id, :string, default: nil

  def create_category_modal(assigns) do
    ~H"""
    <%= if @show do %>
      <div
        id="category-selection-modal"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
        phx-click="skip_category_assignment"
        phx-key="Escape"
        phx-window-keydown="skip_category_assignment"
      >
        <div
          class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4"
          phx-click="category_modal_content_click"
        >
          <!-- 모달 헤더 -->
          <div class="flex items-center justify-between p-6 border-b border-gray-200">
            <h2 class="text-xl font-semibold text-gray-900">카테고리 선택</h2>
            <button
              phx-click="skip_category_assignment"
              class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
          
    <!-- 모달 컨텐츠 -->
          <div class="p-6">
            <p class="text-sm text-gray-600 mb-4">
              포스트에 카테고리를 지정하면 나중에 쉽게 찾을 수 있습니다.
            </p>
            
    <!-- 카테고리 없음 버튼 -->
            <button
              phx-click="assign_category_to_post"
              phx-value-category-id=""
              class="w-full mb-3 p-3 text-left border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200"
            >
              <div class="flex items-center">
                <span class="text-gray-500 mr-2">📝</span>
                <span>카테고리 없음</span>
              </div>
            </button>
            
    <!-- 기존 카테고리들 -->
            <div :for={category <- @categories} class="mb-2">
              <button
                phx-click="assign_category_to_post"
                phx-value-category-id={category.id}
                class="w-full p-3 text-left border border-gray-200 rounded-lg hover:bg-blue-50 hover:border-blue-300 transition-colors duration-200"
              >
                <div class="flex items-center">
                  <span class="text-blue-500 mr-2">🏷️</span>
                  <span>{category.name}</span>
                </div>
              </button>
            </div>
            
    <!-- 새 카테고리 생성 -->
            <div class="mt-4 pt-4 border-t border-gray-200">
              <form phx-submit="create_category" class="space-y-3">
                <div>
                  <label for="new_category_name" class="block text-sm font-medium text-gray-700 mb-1">
                    새 카테고리 만들기
                  </label>
                  <input
                    type="text"
                    id="new_category_name"
                    name="name"
                    value={@category_form["name"] || ""}
                    placeholder="카테고리 이름 입력..."
                    class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    autocomplete="off"
                    phx-debounce="200"
                  />
                </div>
                <button
                  type="submit"
                  class="w-full px-4 py-2 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded-md transition-colors duration-200"
                >
                  만들고 지정하기
                </button>
              </form>
            </div>
            
    <!-- 건너뛰기 버튼 -->
            <div class="mt-4 pt-4 border-t border-gray-200">
              <button
                phx-click="skip_category_assignment"
                class="w-full px-4 py-2 text-sm font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors duration-200"
              >
                나중에 하기
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
