# SetLocale
![](https://img.shields.io/hexpm/v/set_locale.svg) ![](https://img.shields.io/hexpm/dt/set_locale.svg) ![](https://img.shields.io/hexpm/dw/set_locale.svg) ![](https://img.shields.io/coveralls/smeevil/set_locale.svg) ![](https://img.shields.io/github/issues/smeevil/set_locale.svg) ![](https://img.shields.io/github/issues-pr/smeevil/set_locale.svg) ![](https://semaphoreci.com/api/v1/smeevil/currency_formatter/branches/master/shields_badge.svg)


This phoenix plug will help you with I18n url paths.
It can extract the preffered locale from the browsers accept-language header and redirect if an url without locale has been given.
It will extract the locale from the url and check if that is valid and supported. If so it will assign it to ```conn.assigns.locale``` and set ```Gettext``` to that locale as well.
If it is not supported it will redirect to the default locale.

 You might also be interested in [ecto_translate](https://github.com/smeevil/ecto_translate) which can help you with returning translated values of your Ecto data attributes.
## Examples

Given that you define your default language to be "en" :

When someone uses the url : ```http://www.example.org``` they will be redirected to ```http://www.example.org/en/```

When someone uses the url : ```http://www.example.org/foo/bar/baz``` they will be redirected to ```http://www.example.org/en/foo/bar/baz```

When someone uses an unsupported locale in the url they will be redirect to the default one: ```http://www.example.org/de-de/foo/bar/baz``` they will be redirected to ```http://www.example.org/en/foo/bar/baz```

When someone uses a url with no locale prefix, and their browser contains an accept-language string that contains a supported locale they will be redirect to that : ```http://www.example.org/foo/bar/baz``` they will be redirected to ```http://www.example.org/nl-nl/foo/bar/baz```


## Setup

Update your router.ex to include the plug and scope your routes with /:locale

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    ...
    plug SetLocale, [MyApp.Gettext, "en"] #here "en" would be your default locale
  end

  ...

  scope "/", MyApp do
    pipe_through :browser
    get "/", PageController, :dummy #you need this entry to support the default root without a locale, it will never be called
  end

  scope "/:locale", MyApp do
    pipe_through :browser
    get "/", PageController, :index
    ...
  end
end
```



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `set_locale` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:set_locale, "~> 0.1.0"}]
    end
    ```

  2. Ensure `set_locale` is started before your application:

    ```elixir
    def application do
      [applications: [:set_locale]]
    end
    ```

