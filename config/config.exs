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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
