defmodule OfftherecordWeb.CloudflareImages do
  @moduledoc """
  Module for uploading images to Cloudflare Images.
  """
  require Logger

  def upload_image(file_path, user_id, original_filename) do
    Logger.info(
      "Starting upload for file: #{file_path}, user: #{user_id}, filename: #{original_filename}"
    )

    # Check if file exists
    unless File.exists?(file_path) do
      Logger.error("File does not exist: #{file_path}")
      {:error, "File does not exist"}
    else
      # Get configuration
      config = Application.get_env(:offtherecord, :cloudflare)
      account_id = config[:account_id] || "50871ed1a5d048465ef5453feedb23a8"
      api_token = config[:api_token] || System.get_env("CLOUDFLARE_API_TOKEN")

      if is_nil(api_token) do
        Logger.error("No API token found")
        {:error, "API token not configured"}
      else
        base_url = "https://api.cloudflare.com/client/v4/accounts/#{account_id}/images/v1"

        # Generate a unique filename
        timestamp = DateTime.utc_now() |> DateTime.to_unix()
        file_extension = Path.extname(original_filename)

        clean_filename =
          original_filename
          |> Path.basename(file_extension)
          |> String.replace(~r/[^a-zA-Z0-9\-_]/, "")

        custom_id = "offtherecord-web-#{user_id}-#{timestamp}-#{clean_filename}"
        Logger.info("Generated custom_id: #{custom_id}")

        # Read file content
        file_content = File.read!(file_path)
        file_size = byte_size(file_content)
        Logger.info("File size: #{file_size} bytes")

        # Headers without Content-Type (let HTTPoison set it)
        headers = [
          {"Authorization", "Bearer #{api_token}"}
        ]

        # CloudFlare Images API expects this exact multipart format
        form_data = [
          {"file", file_content,
           [
             {"filename", original_filename},
             {"content-type", get_content_type(original_filename)}
           ]},
          {"id", custom_id}
        ]

        Logger.info("Making request to: #{base_url}")
        Logger.info("Custom ID: #{custom_id}")
        Logger.info("File size: #{file_size}")

        case HTTPoison.post(base_url, {:multipart, form_data}, headers,
               timeout: 60_000,
               recv_timeout: 60_000
             ) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            Logger.info("Upload successful, response: #{body}")

            case Jason.decode(body) do
              {:ok, %{"success" => true, "result" => result}} ->
                Logger.info("Parsed result: #{inspect(result)}")

                # Get the public URL from variants
                public_url =
                  case result["variants"] do
                    [first_variant | _] ->
                      first_variant

                    [] ->
                      # Fallback to constructed URL
                      image_id = result["id"]
                      "https://imagedelivery.net/#{account_id}/#{image_id}/public"
                  end

                {:ok,
                 %{
                   id: result["id"],
                   url: public_url,
                   custom_id: custom_id
                 }}

              {:ok, %{"success" => false, "errors" => errors}} ->
                Logger.error("Cloudflare API error: #{inspect(errors)}")
                {:error, "Upload failed: #{inspect(errors)}"}

              {:error, decode_error} ->
                Logger.error("JSON decode error: #{inspect(decode_error)}, body: #{body}")
                {:error, "Failed to parse response"}
            end

          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            Logger.error("Upload failed with status #{status_code}")
            Logger.error("Response body: #{body}")

            # Try to decode error response for more details
            case Jason.decode(body) do
              {:ok, %{"errors" => errors}} ->
                Logger.error("Cloudflare errors: #{inspect(errors)}")
                {:error, "CloudFlare API error: #{inspect(errors)}"}

              {:ok, decoded} ->
                Logger.error("Decoded response: #{inspect(decoded)}")
                {:error, "Upload failed with status #{status_code}"}

              {:error, _} ->
                Logger.error("Could not decode error response")
                {:error, "Upload failed with status #{status_code}: #{body}"}
            end

          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error("HTTP request failed: #{inspect(reason)}")
            {:error, "HTTP request failed: #{reason}"}
        end
      end
    end
  end

  # Get proper content type for the file
  defp get_content_type(filename) do
    case Path.extname(filename) |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      _ -> "application/octet-stream"
    end
  end
end
