use Mix.Config

if Mix.env == :test do

  config :ueberauth, Ueberauth,
    providers: [
      khanacademy: {Ueberauth.Strategy.KhanAcademy, []}
    ]

  config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth,
    client_id: System.get_env("KHANACADEMY_CONSUMER_KEY"),
    client_secret: System.get_env("KHANACADEMY_CONSUMER_SECRET")
end