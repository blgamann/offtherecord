defmodule OfftherecordWeb.Components.Layout do
  @moduledoc """
  Layout components for the Off the Record application.
  """
  use OfftherecordWeb, :verified_routes
  use Phoenix.Component
  import OfftherecordWeb.Components.UI

  @doc """
  Renders the main page header with user info.
  """
  attr :current_user, :map, required: true

  def page_header(assigns) do
    ~H"""
    <header class="relative text-center py-20 mb-10">
      <.user_info current_user={@current_user} />
      <h1 class="text-5xl md:text-6xl font-black text-slate-800 mb-3 tracking-tight">
        off the record
      </h1>
      <p class="text-lg text-slate-600 max-w-md mx-auto">
        새로운 기록을 작성하고 당신만의 이야기를 만들어보세요
      </p>
    </header>
    """
  end

  @doc """
  Renders the user info panel in the top right corner.
  """
  attr :current_user, :map, required: true

  def user_info(assigns) do
    ~H"""
    <div class="absolute top-5 right-5 flex items-center gap-3 bg-white/90 backdrop-blur-sm px-4 py-3 rounded-full shadow-lg">
      <.user_avatar user={@current_user} />
      <span class="font-medium text-slate-800 text-sm">
        {display_name(@current_user)}
      </span>
      <a
        href={~p"/sign-out"}
        class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded-full text-xs font-medium transition-colors"
      >
        로그아웃
      </a>
    </div>
    """
  end

  @doc """
  Renders the main application container.
  """
  slot :inner_block, required: true

  def app_container(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-100 via-purple-50 to-blue-50">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the main content container with responsive padding.
  """
  slot :inner_block, required: true

  def content_container(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-5 py-10">
      {render_slot(@inner_block)}
    </div>
    """
  end

  # Helper function
  defp display_name(user) do
    cond do
      user.name && user.name != "" ->
        user.name

      user.phone_number && user.phone_number != "" ->
        format_phone_display(to_string(user.phone_number))

      true ->
        "User"
    end
  end

  defp format_phone_display(phone_number) do
    if String.length(phone_number) > 4 do
      "***" <> String.slice(phone_number, -4, 4)
    else
      phone_number
    end
  end
end
