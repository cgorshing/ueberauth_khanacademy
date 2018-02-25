use Mix.Config

config :tesla, adapter: :mock

config :ueberauth, Ueberauth,
  providers: [
    khanacademy: {Ueberauth.Strategy.KhanAcademy, []}
  ]

config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth,
  consumer_key: "FAKE_CONSUMER_KEY",
  consumer_secret: "FAKE_CONSUMER_SECRET"
