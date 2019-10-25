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

When someone uses the url : ```http://www.example.org/en-gb/foo/bar/baz``` they will be redirected to ```http://www.example.org/en/foo/bar/baz```

When someone uses an unsupported locale in the url they will be redirected to the default one: ```http://www.example.org/de-de/foo/bar/baz``` they will be redirected to ```http://www.example.org/en/foo/bar/baz```

When someone uses a url with no locale prefix, and their browser contains an accept-language string that contains a supported locale : ```http://www.example.org/foo/bar/baz``` they will be redirected to ```http://www.example.org/nl-nl/foo/bar/baz```

## Fallback chain and precedence

The current precedence and fallback chain is now :

- locale in url (i.e. /nl-nl/)
- cookie
- request headers accept-language
- default locale from config

## Setup

Update your router.ex to include the plug and scope your routes with /:locale

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    ...
    # cookie_key and additional_locales are optional
    plug(SetLocale,
      gettext: MyApp.Gettext,
      default_locale: "en",
      cookie_key: "project_locale",
      additional_locales: ["fr", "es"]
    )
  end

  ...

  scope "/", MyApp do
    pipe_through :browser
    # you need this entry to support the default root without a locale, it will never be called
    get "/", PageController, :dummy
  end

  scope "/:locale", MyApp do
    pipe_through :browser
    get "/", PageController, :index
    ...
  end
end
```

### Options
- gettext: mandatory
- default_locale: mandatory, used as last step in fallback chain
- cookie_key: optional, if given the value of the cookie is part of the fallback chain
- additional_locales: optional, if given it allows to whitelist locales that are not defined via Gettext. Possible scenario: You want to use Gettext and some SaaS localization service (e.g. http://bablic.com/) in parallel. Whitelisting these additional languages allows you to have proper routing for the locales and trigger the wanted JS behaviour depending on the assigned locale in your templates.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `set_locale` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:set_locale, "~> 0.2.1"}]
    end
    ```

  2. Ensure `set_locale` is started before your application:

    ```elixir
    def application do
      [applications: [:set_locale]]
    end
    ```

