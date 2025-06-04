defmodule OfftherecordWeb.Components.Layout do
  @moduledoc """
  Layout components for the Off the Record application.
  Designed with Medium-inspired clean aesthetics with subtle confidential touches.
  """
  use OfftherecordWeb, :verified_routes
  use Phoenix.Component
  import OfftherecordWeb.Components.UI

  @doc """
  Renders the main page header with clean, Medium-style design.
  """
  attr :current_user, :map, required: true

  def page_header(assigns) do
    ~H"""
    <header class="border-b border-gray-100 bg-white">
      <div class="max-w-4xl mx-auto px-6 py-4">
        <div class="flex items-center justify-between">
          <!-- Logo/Brand -->
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-gray-900 rounded-lg flex items-center justify-center">
              <div class="w-3 h-3 bg-white rounded-full opacity-80"></div>
            </div>
            <div>
              <h1 class="text-xl font-bold text-gray-900 tracking-tight">
                Off the Record
              </h1>
              <p class="text-xs text-gray-500 font-medium">
                Personal Archives
              </p>
            </div>
          </div>
          
    <!-- Navigation -->
          <div class="flex items-center space-x-6">
            <.link
              navigate="/"
              class="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
            >
              기록
            </.link>
            <.link
              navigate="/chat"
              class="text-sm font-medium text-blue-600 hover:text-blue-800 transition-colors flex items-center space-x-1"
            >
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.013 8.013 0 01-7-4c0-4.418 3.582-8 8-8s8 3.582 8 8z"
                />
              </svg>
              <span>AI 채팅</span>
            </.link>
          </div>
          
    <!-- User Info -->
          <.user_info current_user={@current_user} />
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Renders the user info with clean design.
  """
  attr :current_user, :map, required: true

  def user_info(assigns) do
    ~H"""
    <div class="flex items-center space-x-3">
      <div class="text-right">
        <p class="text-sm font-medium text-gray-900">
          {display_name(@current_user)}
        </p>
        <p class="text-xs text-gray-500">
          Author
        </p>
      </div>

      <.user_avatar user={@current_user} size="w-10 h-10" />

      <a
        href={~p"/sign-out"}
        class="text-gray-400 hover:text-gray-600 transition-colors p-2"
        title="Sign out"
      >
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
          />
        </svg>
      </a>
    </div>
    """
  end

  @doc """
  Renders the main application container with clean background.
  """
  slot :inner_block, required: true

  def app_container(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the main content container with proper typography spacing.
  """
  slot :inner_block, required: true

  def content_container(assigns) do
    ~H"""
    <main class="max-w-4xl mx-auto px-6 py-8">
      {render_slot(@inner_block)}
    </main>
    """
  end

  @doc """
  Renders a section header with clean typography.
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :string, default: ""

  def section_header(assigns) do
    ~H"""
    <div class={["mb-8", @class]}>
      <h2 class="text-2xl font-bold text-gray-900 mb-1">
        {@title}
      </h2>
      <%= if @subtitle do %>
        <p class="text-gray-600 leading-relaxed">
          {@subtitle}
        </p>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a Medium-style article container.
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def article_container(assigns) do
    ~H"""
    <article class={[
      "bg-white rounded-xl border border-gray-100 shadow-sm",
      "overflow-hidden",
      @class
    ]}>
      {render_slot(@inner_block)}
    </article>
    """
  end

  @doc """
  Renders a subtle floating action area.
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def floating_actions(assigns) do
    ~H"""
    <div class={[
      "fixed bottom-6 right-6 z-10",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # Helper functions
  defp display_name(user) do
    cond do
      user.name && user.name != "" ->
        user.name

      user.email && user.email != "" ->
        user.email |> String.split("@") |> List.first() |> String.capitalize()

      true ->
        "Anonymous"
    end
  end
end
