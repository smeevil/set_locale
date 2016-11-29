defmodule SetLocale do
  import Plug.Conn

  defmodule Config do
    defstruct gettext: nil, default_locale: nil, cookie_key: nil
  end

  def init(gettext: gettext, default_locale: default_locale, cookie_key: cookie_key), do: %Config{gettext: gettext, default_locale: default_locale, cookie_key: cookie_key}
  def init(gettext: gettext, default_locale: default_locale), do: %Config{gettext: gettext, default_locale: default_locale, cookie_key: nil}
  def init(gettext, default_locale) do
    unless Mix.env == :test do
      IO.warn ~S(
        This config style has been deprecated for for set_locale. Please update the old style config:
        plug SetLocale, [Licensor.Gettext, "en-gb"]

        to the new config:
        plug SetLocale, gettext: Licensor.Gettext, default_locale: "en-gb", cookie_key: "preferred_locale"]
      ), Macro.Env.stacktrace(__ENV__)
    end
    %Config{gettext: gettext, default_locale: default_locale, cookie_key: nil}
  end

  def call(%{params: %{"locale" => requested_locale}} = conn, config) do
    if Enum.member?(supported_locales(config), requested_locale) do
      Gettext.put_locale(config.gettext, requested_locale)
      conn |> assign(:locale, requested_locale)
    else
      path = rewrite_path(conn, requested_locale, config)
      conn |> redirect_to(path) |> halt
    end
  end

  def call(conn, config) do
    path = rewrite_path(conn, nil, config)
    conn |> redirect_to(path) |> halt
  end

  defp rewrite_path(%{request_path: request_path} = conn, requested_locale, config) do
    locale = determine_locale(conn, requested_locale, config)

    request_path
    |> maybe_strip_unsupported_locale
    |> localize_path(locale)
  end

  defp determine_locale(conn, nil, config) do
    get_locale_from_cookie(conn, config)
    || get_locale_from_header(conn, config)
    || config.default_locale
  end

  defp determine_locale(conn, requested_locale, config) do
    base = hd String.split(requested_locale, "-")

    if (is_locale?(requested_locale) and Enum.member?(supported_locales(config), base)) do
      base
    else
      determine_locale(conn, nil, config)
    end
  end

  defp supported_locales(config), do: Gettext.known_locales(config.gettext)

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

  defp get_locale_from_cookie(conn, config) do
    conn.cookies[config.cookie_key]
  end

  defp get_locale_from_header(conn, gettext) do
    SetLocale.Headers.extract_accept_language(conn)
    |> Enum.find(nil, fn accepted_locale -> Enum.member?(supported_locales(gettext), accepted_locale) end)
  end


end
