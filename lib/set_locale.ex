defmodule SetLocale do
  import Plug.Conn

  def init(settings), do: settings

  def call(%{params: %{"locale" => requested_locale}} = conn, [gettext, default_locale]) do
    if Enum.member?(supported_locales(gettext), requested_locale) do
      Gettext.put_locale(gettext, requested_locale)
      conn |> assign(:locale, requested_locale)
    else
      path = rewrite_path(conn, gettext, default_locale )
      conn |> redirect_to(path) |> halt
    end
  end

  def call(conn, [gettext, default_locale]) do
    path = rewrite_path(conn, gettext, default_locale)
    Gettext.put_locale(gettext, default_locale)
    conn |> assign(:locale, default_locale) |> redirect_to(path) |> halt
  end

  defp supported_locales(gettext), do: Gettext.known_locales(gettext)

  defp rewrite_path(%{request_path: request_path} = conn, gettext, locale) do
    default_locale = SetLocale.Headers.extract_accept_language(conn) |> Enum.find(locale, fn accepted_locale -> Enum.member?(supported_locales(gettext), accepted_locale) end)
    request_path
    |> maybe_strip_unsupported_locale
    |> localize_path(default_locale)
  end

  defp maybe_strip_unsupported_locale(request_path) do
    [_, maybe_locale | _ ]= String.split(request_path, "/")
    if is_locale?(maybe_locale), do: request_path |> strip_unsupported_locale, else: request_path
  end

  defp is_locale?(maybe_locale), do: Regex.match?(~r/^[a-z]{2}(-[a-z]{2})?$/, maybe_locale)

  defp strip_unsupported_locale(request_path) do
    [_, _ | rest ]= String.split(request_path, "/")
    "/" <> Enum.join(rest, "/")
  end

  defp localize_path("/", locale), do: "/#{locale}"
  defp localize_path(request_path, locale), do: "/#{locale}#{request_path}"

  defp redirect_to(conn, path) do
    path = get_redirect_path(conn, path)
    conn |> Phoenix.Controller.redirect(to: path)
  end

  defp get_redirect_path(%{query_string: query_string}, path) when query_string != "", do: path <> "?#{query_string}"
  defp get_redirect_path(_conn, path), do: path
end

