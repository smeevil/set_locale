defmodule SetLocale do
  import Plug.Conn

  def init(opts) do
    gettext        = Keyword.fetch!(opts, :gettext)
    default_locale = Keyword.fetch!(opts, :default_locale)
    cookie_key  = Keyword.get(opts, :cookie_key)
    [gettext, default_locale, cookie_key]
  end

  def call(%{params: %{"locale" => requested_locale}} = conn, [gettext, default_locale, cookie_key]) do
    if Enum.member?(supported_locales(gettext), requested_locale) do
      Gettext.put_locale(gettext, requested_locale)
      conn |> assign(:locale, requested_locale)
    else
      locale = determine_base_or_default_locale(gettext, requested_locale, default_locale)
      path = rewrite_path(conn, gettext, locale, locale_from_cookie(conn, cookie_key))
      conn |> redirect_to(path) |> halt
    end
  end

  def call(conn, [gettext, default_locale, cookie_key]) do
    path = rewrite_path(conn, gettext, default_locale, locale_from_cookie(conn, cookie_key))
    conn |> redirect_to(path) |> halt
  end

  defp determine_base_or_default_locale(gettext, requested_locale, default_locale) do
    base = hd String.split(requested_locale, "-")
    if (is_locale?(requested_locale) and Enum.member?(supported_locales(gettext), base)), do: base, else: default_locale
  end

  defp supported_locales(gettext), do: Gettext.known_locales(gettext)

  defp rewrite_path(%{request_path: request_path} = conn, gettext, locale, locale_override) do
    default_locale = locale_override ||
                     SetLocale.Headers.extract_accept_language(conn)
                     |> Enum.find(locale, fn accepted_locale -> Enum.member?(supported_locales(gettext), accepted_locale) end)

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

  defp locale_from_cookie(conn, cookie_key) do
    conn.cookies[cookie_key]
  end
end
