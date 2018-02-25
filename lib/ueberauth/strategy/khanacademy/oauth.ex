defmodule Ueberauth.Strategy.KhanAcademy.OAuth do
  use Tesla
  plug Tesla.Middleware.DebugLogger

  require Logger

  @moduledoc """

  Add `consumer_key` and `consumer_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth,
    auth_server: System.get_env("KHAN_AUTH_SERVER"),
    api_server: System.get_env("KHAN_API_SERVER"),
    consumer_key: System.get_env("KHAN_CONSUMER_KEY"),
    consumer_secret: System.get_env("KHAN_CONSUMER_SECRET"),
    redirect_uri: System.get_env("KHAN_REDIRECT_URI")
  """

  def auth_server(configs) do
    configs[:auth_server] || "https://www.khanacademy.org"
  end

  def api_server(configs) do
    configs[:api_server] || "https://api.khanacademy.org"
  end

  def consumer_key(configs) do
    configs[:consumer_key]
  end

  def consumer_secret(configs) do
    configs[:consumer_secret]
  end

  def access_token(token, token_secret, oauth_verifier, opts \\ []) do
    configs = config(opts)

    url = auth_server(configs) <> "/api/auth2/access_token"

    creds = OAuther.credentials(consumer_key: consumer_key(configs), consumer_secret: consumer_secret(configs), token_secret: token_secret)
    params = OAuther.sign("post", url, [{"oauth_token", token}, {"oauth_verifier", oauth_verifier}], creds)

    response = Tesla.request(method: :post, body: "", url: url, query: params, headers: [{"content-type", "text/plain"}])
    #response = Client.request(method: :post, body: "", url: "https://www.khanacademy.org/api/auth2/access_token", query: params, headers: %{})

    #TODO Find a way to parse this better.
    #body: "oauth_token=t4678922844962816&oauth_token_secret=wQGxdQvqmPMmVDNW",

    case response do
      %Tesla.Env{status: 200} ->
        #Convert the string form encoded body to a map
        #I don't like this, would love something else
        #https://stackoverflow.com/questions/42262115/elixir-convert-list-into-a-map
        {:ok, response.body
          |> String.split("&")
          |> Enum.map(fn(x) -> String.split(x, "=") end)
          |> Map.new(fn [k, v] -> {k, v} end)
        }
      error ->
        {:error, error}
    end
  end

  def access_token!(token, secret, verifier, opts \\ []) do
    case access_token(token, secret, verifier, opts) do
      {:ok, token} ->
        token
      error ->
        raise RuntimeError, """
        UeberauthKhanAcademy Error

        #{inspect error}
        """
    end
  end

  def authorize_url!(_token, _params \\ []) do
    raise RuntimeError, "No clue - not sure what to do here"
    #TODO This logic is in the strategy and I think it belongs in here
    #Meaning hitting authorize_url
    #token
    #|> KhanAcademy.authorize_url(params)
    #|> KhanAcademy.request!()
  end

  #The contract provided by ueberauth is the access token, but we have two in a map
  def get_info(tokens, opts \\ []) do
    token = tokens["oauth_token"]
    token_secret = tokens["oauth_token_secret"]

    configs = opts
      |> config()
      |> put_access_token(tokens)

    access_endpoint = "/api/v1/user"
    url = api_server(configs) <> access_endpoint

    creds = OAuther.credentials(consumer_key: consumer_key(configs),
      consumer_secret: consumer_secret(configs),
      token_secret: token_secret)
    params = OAuther.sign("get", url,
      [{"oauth_token", token}],
      creds)

    #response = Tesla.request(method: :get,
      #body: "",
      #url: "https://www.khanacademy.org" <> access_endpoint,
      #query: params,
      #headers: [{"content-type", "text/plain"}])

    response = Tesla.get(url, query: params, headers: [{"content-type", "text/plain"}])

    case response do
      %Tesla.Env{status: 200} ->
        #Convert the string form encoded body to a map
        #I don't like this, would love something else
        #https://stackoverflow.com/questions/42262115/elixir-convert-list-into-a-map
        {:ok, response.body
          |> Poison.decode!
        }
      error ->
        error
    end
  end

  defp config(opts) do
    config = :ueberauth
    |> Application.fetch_env!(Ueberauth.Strategy.KhanAcademy.OAuth)
    |> check_config_key_exists(:consumer_key)
    |> check_config_key_exists(:consumer_secret)

    []
      |> Keyword.merge(config)
      |> Keyword.merge(opts)
  end

  defp put_access_token(config, access_token) do
    tokens = access_token
      |> Map.take([:oauth_token, :oauth_token_secret])
      |> Keyword.new()

    Keyword.merge(config, tokens)
  end

  def request_token(opts \\ []) do

    configs = config(opts)

    params = [{"oauth_callback", configs[:redirect_uri]}]

    creds = OAuther.credentials(consumer_key: consumer_key(configs), consumer_secret: consumer_secret(configs))
    # => %OAuther.Credentials{consumer_key: "dpf43f3p2l4k3l03",
    # consumer_secret: "kd94hf93k423kf44", method: :hmac_sha1,
    # token: "nnch734d00sl2jdk", token_secret: "pfkkdhi9sl3r4s00"}
    url = auth_server(configs) <> "/api/auth2/request_token"

    signed_params = OAuther.sign("post",
      url,
      params,
      creds)

    response = Tesla.request(method: :post, body: "", url: url, query: signed_params, headers: [{"content-type", "text/plain"}])

    case response do
      %Tesla.Env{status: 200} ->
        #redirect_url = "https://www.khanacademy.org/api/auth2/authorize?" <> response.body
        {:ok, response.body}
      error ->
        {:error, error}
    end
  end

  def request_token!(opts \\ []) do

    case request_token(opts) do
      {:ok, token} ->
        token
      error ->
        raise RuntimeError, """
        UeberauthKhanAcademy Error

        #{inspect error}
        """
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect (key)} missing from config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth"
    end
    config
  end
  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.KhanAcademy.OAuth is not a keyword list, as expected"
  end
end
