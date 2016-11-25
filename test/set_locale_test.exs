defmodule SetLocaleTest do
  use ExUnit.Case
  doctest SetLocale

  use Phoenix.ConnTest

  defmodule MyGettext do
    use Gettext, otp_app: :set_locale
  end
  
  @default_options [MyGettext, "en-gb"]

  test "it just passes along options" do
    assert SetLocale.init(["a", "b"]) == ["a", "b"]
  end

  describe "when no locale is given" do
    test "when a root path is requested, it should redirect and set default locale" do
      assert Gettext.get_locale(MyGettext) == "en"
      conn = Phoenix.ConnTest.build_conn(:get, "/", %{}) |> SetLocale.call(@default_options)
      assert redirected_to(conn) == "/en-gb"
      assert conn.assigns == %{locale: "en-gb"}
      assert Gettext.get_locale(MyGettext) == "en-gb"
    end

    test "when headers contain accept-language, it should redirect to that locale if supported" do
      assert Gettext.get_locale(MyGettext) == "en"
      conn = Phoenix.ConnTest.build_conn(:get, "/", %{})
      |> Plug.Conn.put_req_header("accept-language","de, en-gb;q=0.8, nl;q=0.9, en;q=0.7")
      |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl"
    end

    test "when headers contain accept-language but none is accepted, it should redirect to the default locale" do
      assert Gettext.get_locale(MyGettext) == "en"
      conn = Phoenix.ConnTest.build_conn(:get, "/", %{})
      |> Plug.Conn.put_req_header("accept-language","de, fr;q=0.9")
      |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/en-gb"
    end

    test "it redirects to a prefix with default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/foo/bar/baz", %{}) |> SetLocale.call(@default_options)
      assert redirected_to(conn) == "/en-gb/foo/bar/baz"
      assert conn.assigns == %{locale: "en-gb"}
      assert Gettext.get_locale(MyGettext) == "en-gb"
    end
  end

  describe "when an unsupported locale is given" do
    test "it redirects to a prefix with default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/de-at/foo/bar/baz", %{"locale" => "de-at"}) |> SetLocale.call(@default_options)
      assert redirected_to(conn) == "/en-gb/foo/bar/baz"
    end
  end

  describe "when the locale is no locale, but a port of the url" do
    test "it redirects to a prefix with default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
      |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/en-gb/foo/bar"
    end

    test "when headers contain accept-language, it should redirect to the header locale if supported" do
      conn = Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
      |> Plug.Conn.put_req_header("accept-language","de, en-gb;q=0.8, nl;q=0.9, en;q=0.7")
      |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/nl/foo/bar"
    end

    test "when headers contain accept-language, but none is accepted, it should redirect to the default locale" do
      conn = Phoenix.ConnTest.build_conn(:get, "/foo/bar", %{"locale" => "foo"})
      |> Plug.Conn.put_req_header("accept-language","de, fr;q=0.9")
      |> SetLocale.call(@default_options)

      assert redirected_to(conn) == "/en-gb/foo/bar"
    end
  end

  describe "when an existing locale is given" do
    test "with sibling: it should only assign it" do
      conn = Phoenix.ConnTest.build_conn(:get, "/en-gb/foo/bar/baz", %{"locale" => "en-gb"}) |> SetLocale.call(@default_options)
      assert conn.assigns == %{locale: "en-gb"}
      assert conn.status == nil
      assert Gettext.get_locale(MyGettext) == "en-gb"
    end

    test "without sibling: it should only assign it" do
      conn = Phoenix.ConnTest.build_conn(:get, "/nl/foo/bar/baz", %{"locale" => "nl"}) |> SetLocale.call(@default_options)
      assert conn.status == nil
      assert conn.assigns == %{locale: "nl"}
      assert Gettext.get_locale(MyGettext) == "nl"
    end

    test "it should fallback to parent language when sibling does not exist, ie. nl-be should use nl" do
      conn = Phoenix.ConnTest.build_conn(:get, "/nl-be/foo/bar/baz", %{"locale" => "nl-be"}) |> SetLocale.call(@default_options)
      assert redirected_to(conn) == "/nl/foo/bar/baz"
    end

    test "should keep query strings as is" do
      conn = Phoenix.ConnTest.build_conn(:get, "/de-at/foo/bar?foo=bar&baz=true", %{"locale" => "de-at"}) |> SetLocale.call(@default_options)
      assert redirected_to(conn) == "/en-gb/foo/bar?foo=bar&baz=true"
    end
  end
end
