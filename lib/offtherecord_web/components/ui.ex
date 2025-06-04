defmodule OfftherecordWeb.Components.UI do
  @moduledoc """
  Reusable UI components for the Off the Record application.
  Designed with Medium-inspired clean aesthetics with subtle confidential touches.
  """
  use OfftherecordWeb, :verified_routes
  use Phoenix.Component

  @doc """
  Renders a clean, Medium-style button with subtle hover effects.
  """
  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :variant, :string, default: "primary"
  attr :rest, :global
  slot :inner_block, required: true

  def clean_button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      class={[
        "relative overflow-hidden transition-all duration-200 font-medium",
        get_button_styles(@variant, @disabled),
        @class
      ]}
      {@rest}
    >
      <span class="relative z-10">
        {render_slot(@inner_block)}
      </span>
    </button>
    """
  end

  @doc """
  Renders a clean card with subtle shadows, Medium-style.
  """
  attr :class, :string, default: ""
  attr :hover, :boolean, default: true
  slot :inner_block, required: true

  def clean_card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-lg border border-gray-100 shadow-sm",
      @hover && "hover:shadow-md transition-shadow duration-200",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a subtle badge with clean styling.
  """
  attr :class, :string, default: ""
  attr :variant, :string, default: "default"
  slot :inner_block, required: true

  def subtle_badge(assigns) do
    ~H"""
    <div class={[
      "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium",
      get_badge_styles(@variant),
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an empty state with clean, Medium-style design.
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  slot :action

  def clean_empty_state(assigns) do
    ~H"""
    <div class="text-center py-16 px-4">
      <div class="text-4xl mb-4 text-gray-400">{@icon}</div>
      <h3 class="text-xl font-semibold text-gray-900 mb-2">{@title}</h3>
      <p class="text-gray-600 mb-6 max-w-sm mx-auto leading-relaxed">{@description}</p>
      {render_slot(@action)}
    </div>
    """
  end

  @doc """
  Renders a user avatar with clean styling.
  """
  attr :user, :map, required: true
  attr :size, :string, default: "w-8 h-8"
  attr :class, :string, default: ""

  def user_avatar(assigns) do
    ~H"""
    <%= if @user.picture do %>
      <img
        src={@user.picture}
        alt="Profile"
        class={[@size, "rounded-full object-cover border border-gray-200", @class]}
      />
    <% else %>
      <div class={[
        @size,
        "bg-gradient-to-br from-gray-600 to-gray-800 rounded-full",
        "flex items-center justify-center text-white text-sm font-medium",
        "border border-gray-200",
        @class
      ]}>
        {get_user_initial(@user)}
      </div>
    <% end %>
    """
  end

  @doc """
  Renders a clean text input with Medium-style focus states.
  """
  attr :class, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :name, :string, default: ""
  attr :rest, :global

  def clean_input(assigns) do
    ~H"""
    <textarea
      name={@name}
      class={[
        "w-full bg-white border border-gray-200 rounded-lg",
        "p-4 text-gray-900 placeholder:text-gray-500",
        "focus:border-gray-400 focus:ring-0 focus:outline-none",
        "resize-none transition-colors duration-200",
        "text-lg leading-relaxed",
        @class
      ]}
      placeholder={@placeholder}
      {@rest}
    ></textarea>
    """
  end

  @doc """
  Renders a divider with optional text.
  """
  attr :class, :string, default: ""
  attr :text, :string, default: nil

  def divider(assigns) do
    ~H"""
    <div class={["relative flex items-center", @class]}>
      <div class="flex-1 border-t border-gray-200"></div>
      <%= if @text do %>
        <div class="px-4 text-sm text-gray-500 bg-white">{@text}</div>
        <div class="flex-1 border-t border-gray-200"></div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a subtle indicator dot.
  """
  attr :variant, :string, default: "gray"
  attr :class, :string, default: ""

  def indicator_dot(assigns) do
    ~H"""
    <div class={[
      "w-2 h-2 rounded-full",
      get_dot_color(@variant),
      @class
    ]}>
    </div>
    """
  end

  # Private helper functions
  defp get_button_styles("primary", false) do
    "bg-gray-900 hover:bg-gray-800 text-white " <>
      "px-6 py-2.5 rounded-lg font-medium " <>
      "hover:shadow-md active:scale-95"
  end

  defp get_button_styles("secondary", false) do
    "bg-white hover:bg-gray-50 text-gray-900 border border-gray-200 " <>
      "px-6 py-2.5 rounded-lg font-medium " <>
      "hover:shadow-sm active:scale-95"
  end

  defp get_button_styles("ghost", false) do
    "bg-transparent hover:bg-gray-100 text-gray-700 " <>
      "px-4 py-2 rounded-lg font-medium " <>
      "active:scale-95"
  end

  defp get_button_styles("danger", false) do
    "bg-red-600 hover:bg-red-700 text-white " <>
      "px-4 py-2 rounded-lg font-medium " <>
      "hover:shadow-md active:scale-95"
  end

  defp get_button_styles(_, true) do
    "bg-gray-300 text-gray-500 cursor-not-allowed " <>
      "px-6 py-2.5 rounded-lg font-medium"
  end

  defp get_badge_styles("default") do
    "bg-gray-100 text-gray-800"
  end

  defp get_badge_styles("success") do
    "bg-green-100 text-green-800"
  end

  defp get_badge_styles("warning") do
    "bg-yellow-100 text-yellow-800"
  end

  defp get_badge_styles("error") do
    "bg-red-100 text-red-800"
  end

  defp get_badge_styles("info") do
    "bg-blue-100 text-blue-800"
  end

  defp get_dot_color("gray"), do: "bg-gray-400"
  defp get_dot_color("green"), do: "bg-green-500"
  defp get_dot_color("yellow"), do: "bg-yellow-500"
  defp get_dot_color("red"), do: "bg-red-500"
  defp get_dot_color("blue"), do: "bg-blue-500"

  defp get_user_initial(user) do
    display_name =
      cond do
        user.name && user.name != "" ->
          user.name

        user.email && user.email != "" ->
          user.email

        true ->
          "U"
      end

    String.first(display_name) |> String.upcase()
  end
end
