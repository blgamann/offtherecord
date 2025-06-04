defmodule OfftherecordWeb.AuthLive do
  use OfftherecordWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 flex items-center justify-center p-6">
      <div class="max-w-md w-full">
        <!-- Main auth card -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <!-- Header -->
          <div class="px-8 pt-8 pb-6 text-center">
            <div class="w-12 h-12 bg-gray-900 rounded-xl mx-auto mb-4 flex items-center justify-center">
              <div class="w-5 h-5 bg-white rounded-full opacity-90"></div>
            </div>

            <h1 class="text-2xl font-bold text-gray-900 mb-2">
              Welcome to Off the Record
            </h1>

            <p class="text-gray-600 leading-relaxed">
              Sign in to access your personal archive of thoughts and memories.
            </p>
          </div>
          
    <!-- Auth content -->
          <div class="px-8 pb-8">
            <!-- Google Sign-in -->
            <a
              href={~p"/auth/user/google"}
              class="w-full flex items-center justify-center px-6 py-3 border border-gray-200 rounded-xl text-gray-700 font-medium hover:bg-gray-50 hover:border-gray-300 transition-all duration-200 group"
            >
              <svg class="w-5 h-5 mr-3" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Continue with Google
              <svg
                class="w-4 h-4 ml-auto text-gray-400 group-hover:text-gray-600 transition-colors"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </a>
            
    <!-- Privacy note -->
            <div class="mt-6 p-4 bg-gray-50 rounded-lg">
              <div class="flex items-start space-x-3">
                <svg
                  class="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
                <div>
                  <h3 class="text-sm font-medium text-gray-900 mb-1">
                    Private & Secure
                  </h3>
                  <p class="text-xs text-gray-600 leading-relaxed">
                    Your thoughts remain private. We only use your Google account for secure authentication.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Footer -->
        <div class="text-center mt-6">
          <p class="text-xs text-gray-500">
            By signing in, you agree to our privacy practices.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
