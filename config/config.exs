use Mix.Config

if Mix.env == :test do
  config :ueberauth_khanacademy, :http_client, UeberauthKhanAcademy.Support.MockHTTPClient

  config :ueberauth, Ueberauth,
    providers: [
      khanacademy: {Ueberauth.Strategy.KhanAcademy, []}
    ]

  config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth,
    consumer_key: System.get_env("KHANACADEMY_CONSUMER_KEY"),
    consumer_secret: System.get_env("KHANACADEMY_CONSUMER_SECRET")
end
