defmodule SetLocale do
  import Plug.Conn

  defmodule Config do
    @enforce_keys [:gettext, :default_locale]
    defstruct [:gettext, :default_locale, :cookie_key, additional_locales: []]
  end

  def init(opts) when is_tuple(hd(opts)), do: struct!(Config, opts)

  def init([gettext, default_locale]) do
    unless Mix.env() == :test do
      IO.warn(
        ~S(
        This config style has been deprecated for set_locale. Please update the old style config:
        plug SetLocale, [MyApp.Gettext, "en-gb"]

        to the new config:
        plug SetLocale, gettext: MyApp.Gettext, default_locale: "en-gb", cookie_key: "preferred_locale"]
      ),
        Macro.Env.stacktrace(__ENV__)
      )
    end

    %Config{gettext: gettext, default_locale: default_locale}
  end

  def call(
        %{
          request_path: request_path,
          params: %{
            "locale" => requested_locale
          }
        } = conn,
        config
      ) do
    if request_path != "/" and supported_locale?(requested_locale, config) do
      if Enum.member?(config.additional_locales, requested_locale),
        do: Gettext.put_locale(config.gettext, config.default_locale),
        else: Gettext.put_locale(config.gettext, requested_locale)
      assign(conn, :locale, requested_locale)
    else
      path = rewrite_path(conn, requested_locale, config)

      conn
      |> redirect_to(path)
      |> halt
    end
  end

  def call(conn, config) do
    path = rewrite_path(conn, nil, config)

    conn
    |> redirect_to(path)
    |> halt
  end

  defp rewrite_path(%{request_path: request_path} = conn, requested_locale, config) do
    locale = determine_locale(conn, requested_locale, config)

    request_path
    |> maybe_strip_unsupported_locale
    |> localize_path(locale)
  end

  defp determine_locale(conn, nil, config) do
    determined_locale =
      get_locale_from_cookie(conn, config) ||
        get_locale_from_http_referrer(conn) ||
        get_locale_from_header(conn, config)

    if supported_locale?(determined_locale, config),
      do: determined_locale,
      else: config.default_locale
  end

  defp determine_locale(conn, requested_locale, config) do
    base = hd(String.split(requested_locale, "-"))

    if is_locale?(requested_locale) and supported_locale?(base, config) do
      base
    else
      determine_locale(conn, nil, config)
    end
  end

  # Attempt to extract a locale from the HTTP "referer" header.
  # If that url exists and had a language prefix, it's a good indication of what locale the user prefers.
  # And yes, it is referer, not referrer. A typo in the original HTTP spec means it will haunt us forever.
  defp get_locale_from_http_referrer(conn) do
    conn
    |> get_req_header("referer")
    |> case do
      [referrer] when is_binary(referrer) ->
        uri = URI.parse(referrer)
        maybe_extract_locale(uri.path)

      _ ->
        nil
    end
  end

  defp supported_locales(config),
    do: Gettext.known_locales(config.gettext) ++ config.additional_locales

  defp maybe_strip_unsupported_locale(request_path) do
    maybe_locale = maybe_extract_locale(request_path)
    if maybe_locale, do: strip_unsupported_locale(request_path), else: request_path
  end

  defp maybe_extract_locale(request_path) when is_binary(request_path) do
    case String.split(request_path, "/") do
      [_, maybe_locale | _] ->
        if is_locale?(maybe_locale), do: maybe_locale, else: nil

      _ ->
        nil
    end
  end

  defp maybe_extract_locale(_), do: nil

  defp is_locale?(maybe_locale), do: Regex.match?(~r/^[a-z]{2}(-[a-z]{2})?$/, maybe_locale)

  defp strip_unsupported_locale(request_path) do
    [_, _ | rest] = String.split(request_path, "/")
    "/" <> Enum.join(rest, "/")
  end

  defp localize_path("/", locale), do: "/#{locale}"
  defp localize_path(request_path, locale), do: "/#{locale}#{request_path}"

  defp redirect_to(conn, path) do
    path = get_redirect_path(conn, path)
    Phoenix.Controller.redirect(conn, to: path)
  end

  defp get_redirect_path(%{query_string: query_string}, path) when query_string != "",
    do: path <> "?#{query_string}"

  defp get_redirect_path(_conn, path), do: path

  defp get_locale_from_cookie(conn, config), do: conn.cookies[config.cookie_key]

  defp get_locale_from_header(conn, gettext) do
    conn
    |> SetLocale.Headers.extract_accept_language()
    |> Enum.find(nil, fn accepted_locale -> supported_locale?(accepted_locale, gettext) end)
  end

  defp supported_locale?(locale, config), do: Enum.member?(supported_locales(config), locale)
end
