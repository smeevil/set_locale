defmodule SetLocaleTest do
  use ExUnit.Case
  doctest SetLocale

  use Phoenix.ConnTest

  defmodule MyGettext do
    use Gettext, otp_app: :set_locale
  end
  
  @default_options [MyGettext, "en-gb"]

  test "when no locale is given and a root path is requested, it should redirect and set default locale" do
    assert Gettext.get_locale(MyGettext) == "en"
    conn = Phoenix.ConnTest.build_conn(:get, "/", %{}) |> SetLocale.call(@default_options)
    assert redirected_to(conn) == "/en-gb/"
    assert conn.assigns == %{locale: "en-gb"}
    assert Gettext.get_locale(MyGettext) == "en-gb"
  end

  test "when no locale is given and headers contain accept-language, it should redirect to that locale if supported" do
    assert Gettext.get_locale(MyGettext) == "en"
    conn = Phoenix.ConnTest.build_conn(:get, "/", %{})
    |> Plug.Conn.put_req_header("accept-language","de, en-gb;q=0.8, nl;q=0.9, en;q=0.7")
    |> SetLocale.call(@default_options)

    assert redirected_to(conn) == "/nl/"
  end

  test "when no locale is given and headers contain accept-language but non is accepted, it should redirect to the default locale" do
    assert Gettext.get_locale(MyGettext) == "en"
    conn = Phoenix.ConnTest.build_conn(:get, "/", %{})
    |> Plug.Conn.put_req_header("accept-language","de, fr;q=0.9, en-gb;q=0.8, en;q=0.7")
    |> SetLocale.call(@default_options)

    assert redirected_to(conn) == "/en-gb/"
  end

  test "when no locale is given, it redirects to a prefix with default locale" do
    conn = Phoenix.ConnTest.build_conn(:get, "/foo/bar/baz", %{}) |> SetLocale.call(@default_options)
    assert redirected_to(conn) == "/en-gb/foo/bar/baz"
    assert conn.assigns == %{locale: "en-gb"}
    assert Gettext.get_locale(MyGettext) == "en-gb"
  end

  test "when an existing locale like en-gb is given, it should only assign it" do
    conn = Phoenix.ConnTest.build_conn(:get, "/en-gb/foo/bar/baz", %{"locale" => "en-gb"}) |> SetLocale.call(@default_options)
    assert conn.assigns == %{locale: "en-gb"}
    assert conn.status == nil
    assert Gettext.get_locale(MyGettext) == "en-gb"
  end

  test "when an existing locale like nl is given, it should only assign it" do
    conn = Phoenix.ConnTest.build_conn(:get, "/nl/foo/bar/baz", %{"locale" => "nl"}) |> SetLocale.call(@default_options)
    assert conn.assigns == %{locale: "nl"}
    assert conn.status == nil
    assert Gettext.get_locale(MyGettext) == "nl"
  end

  test "when a locale is given that is not supported, it redirects to a default locale" do
    conn = Phoenix.ConnTest.build_conn(:get, "/ar-ae/foo/bar/baz", %{}) |> SetLocale.call(@default_options)
    assert redirected_to(conn) == "/en-gb/foo/bar/baz"
    assert conn.assigns == %{locale: "en-gb"}
    assert Gettext.get_locale(MyGettext) == "en-gb"
  end
end
