## 0.2.3 (2019-02-21)
- Thanks @mtarnovan and @ohrite for relaxing the gettext and phoenix dependencies
- Thanks @narnach for making the locale stick and using the http referer header.
- bumped deps

## 0.2.2 (2017-09-28)
- Thanks @dirkholzapfel for bugfixing an accept-language header like "zh-Hans-CN;q=0.5"
## 0.2.2 (2017-09-28)
- Thanks @dirkholzapfel for adding fallback to "nl" if "nl-nl" is given in accept header
- reformatted code here and there
- bumped dependency versions


## 0.2.2 (2017-03-31)
bumped dependency versions

## 0.2.1 (2017-02-20)
bumped dependency versions

## 0.2.0 (2016-11-29)
Now also taking into account cookie settings for locale as suggested and initially written by @dirkholzapfel (Thank you!).
The current precedence and fallback chain is now :

- locale in url (i.e. /nl-nl/)
- cookie
- request headers accept-language
- default locale from config

This update contains a deprecation waring for the Plug config the new config is now :

```plug SetLocale, gettext: MyApp.Gettext, default_locale: "en-gb", cookie_key: "locale")```

The cookie key is optional, dont forget if you want to use this feature that you application actually stores the preferred locale on the cookie with the same key :)


## 0.1.3 (2016-11-25)
Including a bigfix by @dirkholzapfel which implement correct handling for URLs without given locale, Thanks !

## 0.1.2 (2016-11-07)
Support fallback of base language, for example a requested /en-gb/ can fallback to /en/

## 0.1.1 (2016-11-07)
Root paths not redirect to /en-gb in stead of /en-gb/

## 0.1.0 (2016-11-03)
  - Initial commit
