defmodule OfftherecordWeb.Components.UI do
  @moduledoc """
  Reusable UI components for the Off the Record application.
  """
  use OfftherecordWeb, :verified_routes
  use Phoenix.Component

  @doc """
  Renders a gradient button with hover effects.
  """
  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def gradient_button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      class={[
        if(@disabled,
          do: "bg-gray-400 cursor-not-allowed",
          else: "bg-gradient-to-r from-purple-500 to-blue-600 hover:from-purple-600 hover:to-blue-700"
        ),
        "text-white px-8 py-3 rounded-2xl font-semibold shadow-lg",
        if(!@disabled,
          do: "hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200"
        ),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a card container with shadow and hover effects.
  """
  attr :class, :string, default: ""
  attr :hover, :boolean, default: true
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-3xl shadow-lg border border-slate-200",
      @hover && "hover:shadow-xl transition-shadow duration-300",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a badge with gradient background.
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <div class={[
      "bg-gradient-to-r from-purple-100 to-blue-100 text-slate-800",
      "px-6 py-3 rounded-full font-semibold shadow-sm inline-block",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an empty state with icon and message.
  """
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  slot :action

  def empty_state(assigns) do
    ~H"""
    <div class="text-center py-20">
      <div class="text-6xl mb-6">{@icon}</div>
      <h3 class="text-2xl font-bold text-slate-800 mb-4">{@title}</h3>
      <p class="text-slate-600 mb-8">{@description}</p>
      {render_slot(@action)}
    </div>
    """
  end

  @doc """
  Renders a user avatar with fallback to initials.
  """
  attr :user, :map, required: true
  attr :size, :string, default: "w-8 h-8"
  attr :class, :string, default: ""

  def user_avatar(assigns) do
    ~H"""
    <%= if @user.picture do %>
      <img src={@user.picture} alt="Profile" class={[@size, "rounded-full object-cover", @class]} />
    <% else %>
      <div class={[
        @size,
        "bg-gradient-to-br from-purple-500 to-blue-500 rounded-full",
        "flex items-center justify-center text-white text-sm font-semibold",
        @class
      ]}>
        {get_user_initial(@user)}
      </div>
    <% end %>
    """
  end

  defp get_user_initial(user) do
    display_name =
      cond do
        user.name && user.name != "" ->
          user.name

        user.phone_number && user.phone_number != "" ->
          "***" <> String.slice(to_string(user.phone_number), -4, 4)

        true ->
          "U"
      end

    String.first(display_name)
  end
end
