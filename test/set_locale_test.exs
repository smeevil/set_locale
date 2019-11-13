defmodule SetLocaleTest do
  use ExUnit.Case
  doctest SetLocale

  use Phoenix.ConnTest

  defmodule MyGettext do
    use Gettext, otp_app: :set_locale
  end

  @cookie_key "locale"
  @default_locale "en-gb"
  @default_options %SetLocale.Config{gettext: MyGettext, default_locale: @default_locale}
  @default_options_with_cookie %SetLocale.Config{
    gettext: MyGettext,
    default_locale: @default_locale,
    cookie_key: @cookie_key
  }
  @default_options_with_additional_locales %SetLocale.Config{
    gettext: MyGettext,
    default_locale: @default_locale,
    additional_locales: ["fr", "es"]
  }

  describe "init" do
    test "it supports a legacy config" do
      assert SetLocale.init([MyGettext, "en-gb"]) == %SetLocale.Config{
               gettext: SetLocaleTest.MyGettext,
               default_locale: "en-gb",
               cookie_key: nil,
               additional_locales: []
             }
    end

    test "it enforces gettext key" do
      assert_raise ArgumentError, fn -> SetLocale.init(default_locale: "en-gb") end
    end

    test "it enforces default_locale key" do
      assert_raise ArgumentError, fn -> SetLocale.init(gettext: MyGettext) end
    end

    test "it sets cookie_key to nil if not given" do
      assert SetLocale.init(gettext: MyGettext, default_locale: "en-gb") == %SetLocale.Config{
               gettext: SetLocaleTest.MyGettext,
               default_locale: "en-gb",
               cookie_key: nil
             }
    end

    test "it sets additional_locales to [] if not given" do
      assert SetLocale.init(gettext: MyGettext, default_locale: "en-gb") == %SetLocale.Config{
               gettext: SetLocaleTest.MyGettext,
               default_locale: "en-gb",
               additional_locales: []
             }
    end

    test "it forwards cookie_key option" do
      assert SetLocale.init(gettext: MyGettext, default_locale: "en-gb", cookie_key: "locale") ==
               %SetLocale.Config{
                 gettext: SetLocaleTest.MyGettext,
                 default_locale: "en-gb",
                 cookie_key: "locale"
               }
    end

    test "it forwards additional_locales option" do
      assert SetLocale.init(
               gettext: MyGettext,
               default_locale: "en-gb",
               additional_locales: ["fr", "es"]
             ) == %SetLocale.Config{
               gettext: SetLocaleTest.MyGettext,
               default_locale: "en-gb",
               additional_locales: ["fr", "es"]
             }
    end

    test "it works with all options given" do
      assert SetLocale.init(
               gettext: MyGettext,
               default_locale: "en-gb",
               cookie_key: "locale",
               additional_locales: ["fr", "es"]
             ) == %SetLocale.Config{
               gettext: SetLocaleTest.MyGettext,
               default_locale: "en-gb",
               cookie_key: "locale",
               additional_locales: ["fr", "es"]
             }
    end
  end

  describe "when no locale is given and there is no cookie" do
    test "when a root path is requested, it should redirect to default locale" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}"
    end

    test "when headers contain accept-language, it should redirect to that locale if supported" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("accept-language", "de, en-gb;q=0.8, nl;q=0.9, en;q=0.7")
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl"
    end

    test "when headers contain accept-language with full language tags with country variants,
          it should redirect to the language if country variant is not supported" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header(
          "accept-language",
          "de, en-gb;q=0.8, nl-nl;q=0.9, en;q=0.7, *;q=0.5"
        )
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl"
    end

    test "when headers contain accept-language but none is accepted, it should redirect to the default locale" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("accept-language", "de, fr;q=0.9")
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}"
    end

    test "when headers contain accept-language in incorrect format or language tags with larger range it does not fail" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header(
          "accept-language",
          ",, hell#foo-bar-baz-1234%, zh-Hans-CN;q=0.5"
        )
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}"
    end

    test "it redirects to a prefix with default locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar/baz", %{})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar/baz"
    end
  end

  describe "when no locale is given but there is an cookie" do
    test "when a root path is requested, it should redirect to cookie locale" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "nl")
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/nl"
    end

    test "when headers contain accept-language, it should redirect to cookie locale" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "nl")
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("accept-language", "de, en-gb;q=0.8, en;q=0.7")
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/nl"
    end

    test "it redirects to a prefix with cookie locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar/baz", %{})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "nl")
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/nl/foo/bar/baz"
    end
  end

  describe "when an unsupported locale is given and there is no cookie" do
    test "it redirects to a prefix with default locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/de-at/foo/bar/baz", %{"locale" => "de-at"})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar/baz"
    end
  end

  describe "when an unsupported locale is given but there is a cookie" do
    test "it redirects to a prefix with cookie locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/de-at/foo/bar/baz", %{"locale" => "de-at"})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "nl")
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/nl/foo/bar/baz"
    end

    test "when the cookie is an unsupported locale, it should use the default locale" do
      assert Gettext.get_locale(MyGettext) == "en"

      conn =
        Phoenix.ConnTest.build_conn(:get, "/", %{})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "pl")
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/#{@default_locale}"
    end
  end

  describe "when the locale is no locale, but a part of the url and there is no cookie" do
    test "it redirects to a prefix with default locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar"
    end

    test "when headers contain referer with valid locale in the path, it should use redirect to that locale if supported" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("referer", "/nl/origin")
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl/foo/bar"
    end

    test "when headers contain referer with unsupported locale, it should use redirect to the default locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar")
        |> Plug.Conn.put_req_header("referer", "/pl/origin")
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar"
    end

    test "when headers contain referer without valid locale in the path, it should ignore it and use the default" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("referer", "/origin")
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar"
    end

    test "when headers contain accept-language, it should redirect to the header locale if supported" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("accept-language", "de, en-gb;q=0.8, nl;q=0.9, en;q=0.7")
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl/foo/bar"
    end

    test "when headers contain accept-language, but none is accepted, it should redirect to the default locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("accept-language", "de, fr;q=0.9")
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar"
    end
  end

  describe "when the locale is no locale, but a part of the url and there is a cookie" do
    test "it redirects to a prefix with cookie locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "nl")
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/nl/foo/bar"
    end

    test "when headers contain accept-language, it should redirect to the cookie locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
        |> Plug.Conn.put_resp_cookie(@cookie_key, "nl")
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.put_req_header("accept-language", "de, en-gb;q=0.8, en;q=0.7")
        |> SetLocale.call(@default_options_with_cookie)

      assert redirected_to(conn) == "/nl/foo/bar"
    end
  end

  describe "when an existing locale is given" do
    test "when a root path is requested, it should redirect to the requested locale" do
      assert Gettext.get_locale(MyGettext) == "en"
      conn = Phoenix.ConnTest.build_conn(:get, "/", %{"locale" => "nl"})
             |> Plug.Conn.fetch_cookies()
             |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl"
    end

    test "with sibling: it should only assign it" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/en-gb/foo/bar/baz", %{"locale" => "en-gb"})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert conn.status == nil
      assert conn.assigns == %{locale: "en-gb"}
      assert Gettext.get_locale(MyGettext) == "en-gb"
    end

    test "without sibling: it should only assign it" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/nl/foo/bar/baz", %{"locale" => "nl"})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert conn.status == nil
      assert conn.assigns == %{locale: "nl"}
      assert Gettext.get_locale(MyGettext) == "nl"
    end

    test "it should fallback to parent language when sibling does not exist, ie. nl-be should use nl" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/nl-be/foo/bar/baz", %{"locale" => "nl-be"})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl/foo/bar/baz"
    end

    test "should keep query strings as is" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/de-at/foo/bar?foo=bar&baz=true", %{
          "locale" => "de-at"
        })
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/#{@default_locale}/foo/bar?foo=bar&baz=true"
    end

    test "it should allow non Gettext locales that are whitelisted via additional_locales option
          and assign it, but should set Gettext to the default_locale" do
      conn =
        Phoenix.ConnTest.build_conn(:get, "/fr/foo/bar/baz", %{"locale" => "fr"})
        |> Plug.Conn.fetch_cookies()
        |> SetLocale.call(@default_options_with_additional_locales)

      assert conn.status == nil
      assert conn.assigns == %{locale: "fr"}
      assert Gettext.get_locale(MyGettext) == @default_locale
    end
  end
end
