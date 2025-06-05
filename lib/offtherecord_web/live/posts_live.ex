defmodule OfftherecordWeb.PostsLive do
  use Phoenix.LiveView, layout: false
  use OfftherecordWeb, :verified_routes
  alias Offtherecord.Record.Post

  import OfftherecordWeb.Components.Posts
  import OfftherecordWeb.Components.Layout
  import Plug.CSRFProtection, only: [get_csrf_token: 0]

  on_mount {OfftherecordWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    posts = list_posts(current_user)
    categories = list_categories(current_user)

    IO.inspect(posts)

    socket =
      socket
      |> assign(:posts, posts)
      |> assign(:post_count, length(posts))
      |> assign(:form, to_form(%{"content" => "", "image_url" => ""}))
      |> assign(:uploading, false)
      |> assign(:uploaded_image_url, nil)
      # 미리보기용 Base64 URL
      |> assign(:preview_image_url, nil)
      |> assign(:selected_file_info, nil)
      |> assign(:upload_error, nil)
      # 이미지 모달 상태
      |> assign(:show_modal, false)
      |> assign(:modal_image_url, nil)
      # 포스트 작성 모달 상태
      |> assign(:show_compose_modal, false)
      # 카테고리 관련 상태
      |> assign(:categories, categories)
      |> assign(:selected_category_id, nil)
      |> assign(:show_category_modal, false)
      |> assign(:pending_post_id, nil)
      |> assign(:category_form, %{})

    {:ok, socket}
  end

  @impl true
  def handle_event("create_post", %{"content" => content, "image_url" => _}, socket) do
    require Logger
    Logger.info("=== CREATE POST EVENT ===")
    Logger.info("Content: #{inspect(content)}")
    Logger.info("Content length: #{String.length(content || "")}")
    Logger.info("Uploading: #{socket.assigns.uploading}")

    # 빈 내용 체크
    cond do
      content == nil or String.trim(content) == "" ->
        Logger.warning("Empty content received")
        socket = put_flash(socket, :error, "내용을 입력해주세요.")
        {:noreply, socket}

      # 업로드가 진행 중이면 포스트 생성을 막습니다
      socket.assigns.uploading ->
        socket = put_flash(socket, :error, "이미지 업로드가 완료될 때까지 기다려주세요.")
        {:noreply, socket}

      true ->
        # 업로드된 이미지 URL이 있으면 사용, 없으면 빈 문자열
        image_url = socket.assigns.uploaded_image_url || ""

        case create_post(
               %{
                 content: content,
                 image_url: image_url
               },
               socket.assigns.current_user
             ) do
          {:ok, post} ->
            posts = list_posts(socket.assigns.current_user)
            categories = list_categories(socket.assigns.current_user)

            socket =
              socket
              |> assign(:posts, posts)
              |> assign(:post_count, length(posts))
              |> assign(:form, to_form(%{"content" => "", "image_url" => ""}))
              |> assign(:uploaded_image_url, nil)
              |> assign(:preview_image_url, nil)
              |> assign(:selected_file_info, nil)
              |> assign(:upload_error, nil)
              |> assign(:show_compose_modal, false)
              # 카테고리 선택 모달 표시
              |> assign(:show_category_modal, true)
              |> assign(:pending_post_id, post.id)
              |> assign(:categories, categories)
              |> assign(:category_form, %{})
              |> put_flash(:info, "포스트가 생성되었습니다! 카테고리를 선택해주세요.")

            {:noreply, socket}

          {:error, changeset} ->
            Logger.error("Post creation failed: #{inspect(changeset)}")
            socket = put_flash(socket, :error, "포스트 생성에 실패했습니다.")
            {:noreply, socket}
        end
    end
  end

  @impl true
  def handle_event("validate_post", params, socket) do
    require Logger
    Logger.info("=== VALIDATE POST EVENT ===")
    Logger.info("Validate post params: #{inspect(params)}")

    # 더 안전한 폼 생성
    form_data = %{
      "content" => Map.get(params, "content", ""),
      "image_url" => Map.get(params, "image_url", "")
    }

    form = to_form(form_data)
    {:noreply, assign(socket, :form, form)}
  end

  # JavaScript에서 파일이 선택되었을 때 호출
  @impl true
  def handle_event("file_selected", %{"file" => file_data}, socket) do
    require Logger
    Logger.info("File selected via JavaScript: #{inspect(file_data)}")

    # Base64 데이터에서 실제 파일 데이터 추출
    case decode_file_data(file_data) do
      {:ok, {filename, file_binary}} ->
        # 즉시 미리보기 보여주기
        preview_url = file_data["data"]

        socket =
          socket
          |> assign(:uploading, true)
          |> assign(:preview_image_url, preview_url)
          |> assign(:selected_file_info, %{
            name: filename,
            size: byte_size(file_binary)
          })
          |> assign(:upload_error, nil)

        # 백그라운드에서 업로드 처리
        parent_pid = self()

        Task.start(fn ->
          upload_result =
            upload_file_binary(file_binary, filename, socket.assigns.current_user.id)

          send(parent_pid, {:upload_complete, upload_result})
        end)

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Failed to decode file: #{reason}")

        socket =
          socket
          |> assign(:upload_error, "파일 처리에 실패했습니다.")
          |> put_flash(:error, "파일 처리에 실패했습니다.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:upload_complete, result}, socket) do
    require Logger
    Logger.info("Upload completed: #{inspect(result)}")

    case result do
      {:ok, image_url} ->
        socket =
          socket
          |> assign(:uploaded_image_url, image_url)
          |> assign(:uploading, false)
          |> assign(:selected_file_info, nil)
          |> put_flash(:info, "이미지가 성공적으로 업로드되었습니다!")

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Upload failed: #{reason}")

        socket =
          socket
          |> assign(:uploading, false)
          |> assign(:preview_image_url, nil)
          |> assign(:upload_error, "이미지 업로드에 실패했습니다.")
          |> put_flash(:error, "이미지 업로드에 실패했습니다.")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_uploaded_image", _params, socket) do
    socket =
      socket
      |> assign(:uploaded_image_url, nil)
      |> assign(:preview_image_url, nil)
      |> assign(:upload_error, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_upload", _params, socket) do
    socket =
      socket
      |> assign(:selected_file_info, nil)
      |> assign(:uploading, false)
      |> assign(:preview_image_url, nil)
      |> assign(:upload_error, nil)

    {:noreply, socket}
  end

  # 카테고리 선택 이벤트
  @impl true
  def handle_event("select_category", %{"category-id" => category_id}, socket) do
    # 빈 문자열이면 nil로 변환 (전체 선택)
    selected_category_id = if category_id == "", do: nil, else: category_id

    # 포스트 필터링
    all_posts = list_posts(socket.assigns.current_user)
    filtered_posts = filter_posts_by_category(all_posts, selected_category_id)

    socket =
      socket
      |> assign(:selected_category_id, selected_category_id)
      |> assign(:posts, filtered_posts)
      |> assign(:post_count, length(filtered_posts))

    {:noreply, socket}
  end

  # 새 카테고리 생성 모달 열기
  @impl true
  def handle_event("open_create_category_modal", _params, socket) do
    require Logger
    Logger.info("=== OPEN CREATE CATEGORY MODAL ===")

    socket =
      socket
      |> assign(:show_category_modal, true)
      |> assign(:category_form, %{})
      |> put_flash(:info, "새 카테고리 모달이 열렸습니다!")

    Logger.info("Modal state set to: #{socket.assigns.show_category_modal}")
    {:noreply, socket}
  end

  # 카테고리 생성 모달 닫기
  @impl true
  def handle_event("close_create_category_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_category_modal, false)
      |> assign(:category_form, %{})

    {:noreply, socket}
  end

  # 카테고리 생성
  @impl true
  def handle_event("create_category", %{"name" => name}, socket) do
    case String.trim(name) do
      "" ->
        socket = put_flash(socket, :error, "카테고리 이름을 입력해주세요.")
        {:noreply, socket}

      category_name ->
        case create_category(category_name, socket.assigns.current_user) do
          {:ok, category} ->
            # 대기 중인 포스트가 있으면 바로 카테고리 지정
            pending_post_id = socket.assigns.pending_post_id

            if pending_post_id do
              case assign_post_category(pending_post_id, category.id, socket.assigns.current_user) do
                {:ok, _post} ->
                  # 포스트 목록 새로고침
                  posts = list_posts(socket.assigns.current_user)

                  filtered_posts =
                    filter_posts_by_category(posts, socket.assigns.selected_category_id)

                  socket =
                    socket
                    |> assign(:posts, filtered_posts)
                    |> assign(:post_count, length(filtered_posts))
                    |> assign(:categories, list_categories(socket.assigns.current_user))
                    |> assign(:show_category_modal, false)
                    |> assign(:pending_post_id, nil)
                    |> assign(:category_form, %{})
                    |> put_flash(:info, "새 카테고리가 생성되고 지정되었습니다!")

                  {:noreply, socket}

                {:error, _error} ->
                  socket = put_flash(socket, :error, "카테고리 지정에 실패했습니다.")
                  {:noreply, socket}
              end
            else
              # 일반적인 카테고리 생성 (+ 새 카테고리 버튼에서 온 경우)
              categories = list_categories(socket.assigns.current_user)

              socket =
                socket
                |> assign(:categories, categories)
                |> assign(:show_category_modal, false)
                |> assign(:category_form, %{})
                |> put_flash(:info, "카테고리가 생성되었습니다!")

              {:noreply, socket}
            end

          {:error, error} ->
            error_message =
              case error do
                %{errors: [%{message: message}]} -> message
                _ -> "카테고리 생성에 실패했습니다."
              end

            socket = put_flash(socket, :error, error_message)
            {:noreply, socket}
        end
    end
  end

  # 카테고리 모달 컨텐츠 클릭 (이벤트 버블링 방지)
  @impl true
  def handle_event("category_modal_content_click", _params, socket) do
    {:noreply, socket}
  end

  # 포스트에 카테고리 지정
  @impl true
  def handle_event("assign_category_to_post", %{"category-id" => category_id}, socket) do
    pending_post_id = socket.assigns.pending_post_id

    if pending_post_id do
      # 카테고리 ID가 빈 문자열이면 nil로 변환
      category_id = if category_id == "", do: nil, else: category_id

      case assign_post_category(pending_post_id, category_id, socket.assigns.current_user) do
        {:ok, _post} ->
          # 포스트 목록 새로고침
          posts = list_posts(socket.assigns.current_user)

          # 필터링도 적용
          filtered_posts = filter_posts_by_category(posts, socket.assigns.selected_category_id)

          socket =
            socket
            |> assign(:posts, filtered_posts)
            |> assign(:post_count, length(filtered_posts))
            |> assign(:show_category_modal, false)
            |> assign(:pending_post_id, nil)
            |> assign(:category_form, %{})
            |> put_flash(:info, "카테고리가 지정되었습니다!")

          {:noreply, socket}

        {:error, _error} ->
          socket = put_flash(socket, :error, "카테고리 지정에 실패했습니다.")
          {:noreply, socket}
      end
    else
      socket = put_flash(socket, :error, "지정할 포스트를 찾을 수 없습니다.")
      {:noreply, socket}
    end
  end

  # 카테고리 지정 건너뛰기
  @impl true
  def handle_event("skip_category_assignment", _params, socket) do
    socket =
      socket
      |> assign(:show_category_modal, false)
      |> assign(:pending_post_id, nil)
      |> assign(:category_form, %{})
      |> put_flash(:info, "포스트가 생성되었습니다!")

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_post", %{"id" => id}, socket) do
    case delete_post(id, socket.assigns.current_user) do
      :ok ->
        posts = list_posts(socket.assigns.current_user)

        socket =
          socket
          |> assign(:posts, posts)
          |> assign(:post_count, length(posts))
          |> put_flash(:info, "포스트가 삭제되었습니다.")

        {:noreply, socket}

      {:error, _} ->
        socket = put_flash(socket, :error, "포스트 삭제에 실패했습니다.")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_compose_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_compose_modal, true)
      |> assign(:form, to_form(%{"content" => "", "image_url" => ""}))
      |> assign(:uploaded_image_url, nil)
      |> assign(:preview_image_url, nil)
      |> assign(:selected_file_info, nil)
      |> assign(:upload_error, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_compose_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_compose_modal, false)
      |> assign(:uploaded_image_url, nil)
      |> assign(:preview_image_url, nil)
      |> assign(:selected_file_info, nil)
      |> assign(:upload_error, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_image_modal", %{"image-url" => image_url}, socket) do
    socket =
      socket
      |> assign(:show_modal, true)
      |> assign(:modal_image_url, image_url)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_image_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:modal_image_url, nil)

    {:noreply, socket}
  end

  # 기본 info 핸들러
  @impl true
  def handle_info(msg, socket) do
    require Logger
    Logger.debug("Unhandled info message: #{inspect(msg)}")
    {:noreply, socket}
  end

  # Base64 파일 데이터 디코딩
  defp decode_file_data(%{"name" => filename, "data" => data_url}) do
    try do
      # data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA... 형식
      case String.split(data_url, ",", parts: 2) do
        [_header, base64_data] ->
          file_binary = Base.decode64!(base64_data)
          {:ok, {filename, file_binary}}

        _ ->
          {:error, "Invalid data URL format"}
      end
    rescue
      error ->
        {:error, "Failed to decode base64: #{inspect(error)}"}
    end
  end

  # 파일 바이너리를 CloudFlare에 업로드
  defp upload_file_binary(file_binary, filename, user_id) do
    # 임시 파일 생성
    temp_dir = System.tmp_dir!()
    temp_filename = "upload_#{:rand.uniform(1_000_000)}_#{filename}"
    temp_path = Path.join(temp_dir, temp_filename)

    try do
      # 임시 파일에 쓰기
      File.write!(temp_path, file_binary)

      # CloudFlare 업로드
      result = OfftherecordWeb.CloudflareImages.upload_image(temp_path, user_id, filename)

      # 임시 파일 삭제
      File.rm(temp_path)

      case result do
        {:ok, image_data} -> {:ok, image_data.url}
        error -> error
      end
    rescue
      error ->
        # 에러 발생 시 임시 파일 정리
        File.rm(temp_path)
        {:error, "Upload failed: #{inspect(error)}"}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="ko" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <title>Off the Record</title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </head>
      <body>
        <.app_container>
          <.page_header current_user={@current_user} />

          <.content_container>
            <.compose_button current_user={@current_user} />
            <.posts_timeline
              posts={@posts}
              show_modal={@show_modal}
              modal_image_url={@modal_image_url}
            />
          </.content_container>
          
    <!-- 카테고리 가로 스크롤 (하단 고정) -->
          <.category_horizontal_list
            categories={@categories}
            selected_category_id={@selected_category_id}
          />

          <.compose_modal
            show={@show_compose_modal}
            form={@form}
            uploading={@uploading}
            uploaded_image_url={@uploaded_image_url}
            preview_image_url={@preview_image_url}
            selected_file_info={@selected_file_info}
            upload_error={@upload_error}
            current_user={@current_user}
          />

          <.create_category_modal
            show={@show_category_modal}
            categories={@categories}
            category_form={@category_form}
            pending_post_id={@pending_post_id}
          />
        </.app_container>
      </body>
    </html>
    """
  end

  # Private functions for data operations
  defp list_posts(current_user) do
    case Ash.read(Post,
           domain: Offtherecord.Record,
           actor: current_user,
           load: [:user, :category]
         ) do
      {:ok, posts} ->
        posts
        |> Enum.sort_by(& &1.created_at, {:desc, DateTime})

      {:error, _} ->
        []
    end
  end

  defp list_categories(current_user) do
    alias Offtherecord.Record.Category

    case Ash.read(Category, domain: Offtherecord.Record, actor: current_user) do
      {:ok, categories} ->
        categories
        |> Enum.sort_by(& &1.inserted_at, {:asc, DateTime})

      {:error, _} ->
        []
    end
  end

  defp filter_posts_by_category(posts, nil), do: posts

  defp filter_posts_by_category(posts, category_id) do
    Enum.filter(posts, &(&1.category_id == category_id))
  end

  defp create_category(name, current_user) do
    alias Offtherecord.Record.Category

    Category
    |> Ash.Changeset.for_create(:create, %{name: name}, actor: current_user)
    |> Ash.create(domain: Offtherecord.Record)
  end

  defp create_post(attrs, current_user) do
    Post
    |> Ash.Changeset.for_create(:create, attrs, actor: current_user)
    |> Ash.create(domain: Offtherecord.Record)
  end

  defp delete_post(id, current_user) do
    case Ash.get(Post, id, domain: Offtherecord.Record, actor: current_user) do
      {:ok, post} ->
        post
        |> Ash.Changeset.for_destroy(:destroy)
        |> Ash.destroy(domain: Offtherecord.Record, actor: current_user)

      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp assign_post_category(post_id, category_id, current_user) do
    case Ash.get(Post, post_id, domain: Offtherecord.Record, actor: current_user) do
      {:ok, post} ->
        post
        |> Ash.Changeset.for_update(:assign_category, %{category_id: category_id},
          actor: current_user
        )
        |> Ash.update(domain: Offtherecord.Record)

      {:error, _} ->
        {:error, :not_found}
    end
  end
end
