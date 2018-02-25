# Überauth Khan Academy

> Khan Academy strategy for Überauth.

_Note_: Sessions are required for this strategy.

[Source code is available on Github](https://github.com/cgorshing/ueberauth_khanacademy).<br/>
[Package is available on hex](https://hex.pm/packages/ueberauth_khanacademy).

## Installation

1. Register your app at [Khan Academy](https://www.khanacademy.org/api-apps/register).

1. Add `:ueberauth_khanacademy` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_khanacademy, "~> 0.0.4"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_khanacademy]]
    end
    ```

1. Add Khan Academy to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        khanacademy: {Ueberauth.Strategy.KhanAcademy, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth,
      consumer_key: System.get_env("KHANACADEMY_CONSUMER_KEY"),
      consumer_secret: System.get_env("KHANACADEMY_CONSUMER_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/khanacademy

Currently no permissions or scope is available.

## License

Please see [LICENSE](https://github.com/cgorshing/ueberauth_khanacademy/blob/master/LICENSE) for licensing details.

## Acknowledgment

My best to [Christopher Adams](https://github.com/christopheradams) as his [Flickr strategy](https://github.com/christopheradams/ueberauth_flickr) was the starting point for this application. Appreciate your work sir!
