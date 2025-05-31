defmodule OfftherecordWeb.DashboardLive do
  use OfftherecordWeb, :live_view

  on_mount {OfftherecordWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  # Private helper functions

  defp display_name(user) do
    cond do
      user.name && user.name != "" ->
        to_string(user.name)

      user.email && user.email != "" ->
        to_string(user.email) |> String.split("@") |> hd() |> String.capitalize()

      user.phone_number && user.phone_number != "" ->
        format_phone_display(to_string(user.phone_number))

      true ->
        "User"
    end
  end

  defp format_phone_display(phone_number) do
    # +821046432757 -> "***2757" 형태로 표시
    if String.length(phone_number) > 4 do
      "***" <> String.slice(phone_number, -4, 4)
    else
      phone_number
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <!-- Navigation -->
      <nav class="backdrop-blur-xl bg-white/10 border-b border-white/20">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex items-center">
              <div class="h-8 w-8 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center mr-3">
                <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
              </div>
              <h1 class="text-xl font-bold text-white">Off The Record</h1>
            </div>
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-3">
                <%= if @current_user.picture do %>
                  <img
                    src={@current_user.picture}
                    alt="Profile picture"
                    class="w-8 h-8 rounded-full border-2 border-white/20"
                  />
                <% else %>
                  <div class="w-8 h-8 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full border-2 border-white/20 flex items-center justify-center">
                    <span class="text-white text-sm font-semibold">
                      {String.first(display_name(@current_user))}
                    </span>
                  </div>
                <% end %>
                <span class="text-white/90 text-sm font-medium">
                  {display_name(@current_user)}
                </span>
              </div>
              <a
                href={~p"/sign-out"}
                class="bg-red-500/20 text-red-300 px-4 py-2 rounded-lg text-sm hover:bg-red-500/30 transition-all duration-200 border border-red-500/30"
              >
                Sign Out
              </a>
            </div>
          </div>
        </div>
      </nav>
      
    <!-- Main content -->
      <main class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <!-- Welcome Section -->
        <div class="mb-8">
          <h2 class="text-4xl font-bold text-white mb-2">
            Welcome back, {display_name(@current_user)}! 👋
          </h2>
          <p class="text-white/70 text-lg">
            Ready to manage your off-the-record content?
          </p>
        </div>
        
    <!-- Dashboard Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          <!-- Profile Card -->
          <div class="backdrop-blur-xl bg-white/10 border border-white/20 rounded-2xl p-6">
            <div class="flex items-center space-x-4">
              <%= if @current_user.picture do %>
                <img
                  src={@current_user.picture}
                  alt="Profile picture"
                  class="w-16 h-16 rounded-full border-3 border-gradient-to-r from-purple-500 to-pink-500"
                />
              <% else %>
                <div class="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
                  <span class="text-white text-xl font-bold">
                    {String.first(display_name(@current_user))}
                  </span>
                </div>
              <% end %>
              <div>
                <h3 class="text-white font-semibold text-lg">{display_name(@current_user)}</h3>
                <p class="text-white/70 text-sm">
                  {@current_user.email || @current_user.phone_number}
                </p>
                <div class="flex items-center mt-1">
                  <div class="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                  <span class="text-green-400 text-xs">Active</span>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Stats Card -->
          <div class="backdrop-blur-xl bg-white/10 border border-white/20 rounded-2xl p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-white/70 text-sm font-medium uppercase tracking-wide">Total Posts</h3>
                <p class="text-white text-3xl font-bold mt-1">0</p>
                <p class="text-green-400 text-sm mt-1">+0% from last month</p>
              </div>
              <div class="bg-blue-500/20 p-3 rounded-xl">
                <svg
                  class="w-6 h-6 text-blue-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
              </div>
            </div>
          </div>
          
    <!-- Activity Card -->
          <div class="backdrop-blur-xl bg-white/10 border border-white/20 rounded-2xl p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-white/70 text-sm font-medium uppercase tracking-wide">
                  Last Activity
                </h3>
                <p class="text-white text-lg font-semibold mt-1">Just now</p>
                <p class="text-white/70 text-sm mt-1">Logged in</p>
              </div>
              <div class="bg-purple-500/20 p-3 rounded-xl">
                <svg
                  class="w-6 h-6 text-purple-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Quick Actions -->
        <div class="backdrop-blur-xl bg-white/10 border border-white/20 rounded-2xl p-8">
          <h3 class="text-white text-2xl font-bold mb-6">Quick Actions</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <button class="bg-gradient-to-r from-purple-500 to-pink-500 text-white p-4 rounded-xl font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200">
              <svg class="w-6 h-6 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              Create Post
            </button>
            <button class="bg-white/10 text-white p-4 rounded-xl font-semibold hover:bg-white/20 transition-all duration-200 border border-white/20">
              <svg class="w-6 h-6 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              Analytics
            </button>
            <button class="bg-white/10 text-white p-4 rounded-xl font-semibold hover:bg-white/20 transition-all duration-200 border border-white/20">
              <svg class="w-6 h-6 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              Settings
            </button>
            <button class="bg-white/10 text-white p-4 rounded-xl font-semibold hover:bg-white/20 transition-all duration-200 border border-white/20">
              <svg class="w-6 h-6 mx-auto mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Help
            </button>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
