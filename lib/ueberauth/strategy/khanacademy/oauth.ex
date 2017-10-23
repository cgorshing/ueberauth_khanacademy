defmodule Ueberauth.Strategy.KhanAcademy.OAuth do
  use Tesla
  plug Tesla.Middleware.DebugLogger

  @moduledoc """
  OAuth1 for Flickr.

  Add `consumer_key` and `consumer_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Flickr.OAuth,
    consumer_key: System.get_env("FLICKR_CONSUMER_KEY"),
    consumer_secret: System.get_env("FLICKR_CONSUMER_SECRET"),
    redirect_uri: System.get_env("FLICKR_REDIRECT_URI")
  """

  def access_token(token, token_secret, oauth_verifier, _opts \\ []) do
    #config = config(opts)

    #access_endpoint = "/api/auth/access_token"
    creds = OAuther.credentials(consumer_key: "GZ5p4ytLr7XEbLxG", consumer_secret: "J2wQynLGvN2zzEum", token_secret: token_secret)
    params = OAuther.sign("post", "https://www.khanacademy.org/api/auth2/access_token", [{"oauth_token", token}, {"oauth_verifier", oauth_verifier}], creds)

    response = Tesla.request(method: :post, body: "", url: "https://www.khanacademy.org/api/auth2/access_token", query: params, headers: [{"content-type", "text/plain"}])
    #response = Client.request(method: :post, body: "", url: "https://www.khanacademy.org/api/auth2/access_token", query: params, headers: %{})

    #TODO Find a way to parse this better.
    #body: "oauth_token=t4678922844962816&oauth_token_secret=wQGxdQvqmPMmVDNW",

    #IO.puts "+++ okay what does the body look like now?"
    #IO.inspect response
    #IO.inspect response.body

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
    #token
    #|> KhanAcademy.authorize_url(params)
    #|> KhanAcademy.request!()
  end

  #The contract provided by ueberauth is the access token, but we have two in a map
  def get_info(tokens, opts \\ []) do
    #IO.puts "+++ get info"
    #IO.inspect tokens
    #IO.puts "+++ opts"
    #IO.inspect opts

    token = tokens["oauth_token"]
    token_secret = tokens["oauth_token_secret"]

    _config =
      opts
      |> config()
      |> put_access_token(tokens)

    api_server = "https://api.khanacademy.org"
    access_endpoint = "/api/v1/user"
    creds = OAuther.credentials(consumer_key: "GZ5p4ytLr7XEbLxG",
      consumer_secret: "J2wQynLGvN2zzEum",
      token_secret: token_secret)
    params = OAuther.sign("get", api_server <> access_endpoint,
      [{"oauth_token", token}],
      creds)

    #response = Tesla.request(method: :get,
      #body: "",
      #url: "https://www.khanacademy.org" <> access_endpoint,
      #query: params,
      #headers: [{"content-type", "text/plain"}])

    response = Tesla.get(api_server <> access_endpoint, query: params, headers: [{"content-type", "text/plain"}])

    #IO.puts "++++ Response from Khan for /api/v1/user"
    #IO.inspect response
    #IO.puts response.body

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
    IO.puts "+++ config(opts)"

    config =
    :ueberauth
    |> Application.fetch_env!(Ueberauth.Strategy.KhanAcademy.OAuth)
    |> check_config_key_exists(:client_id)
    |> check_config_key_exists(:client_secret)

    #IO.inspect "+++ opts"
    #IO.inspect config
    #IO.inspect opts

    _client_opts = []
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    #OAuth2.Client.new(client_opts)
  end

  defp put_access_token(config, access_token) do
    tokens =
      access_token
      |> Map.take([:oauth_token, :oauth_token_secret])
      |> Keyword.new()

    Keyword.merge(config, tokens)
  end

  def request_token(opts \\ []) do
    #IO.puts "+++2"
    #config = config(opts)
    #IO.puts "+++3"
    #IO.inspect config
    #IO.puts "+++4"



    #Tesla.post("http://posttestserver.com/post.php", query: [dir: "blah"])
    #Tesla.post("http://posttestserver.com/post.php")

    creds = OAuther.credentials(consumer_key: "GZ5p4ytLr7XEbLxG", consumer_secret: "J2wQynLGvN2zzEum")
    # => %OAuther.Credentials{consumer_key: "dpf43f3p2l4k3l03",
    # consumer_secret: "kd94hf93k423kf44", method: :hmac_sha1,
    # token: "nnch734d00sl2jdk", token_secret: "pfkkdhi9sl3r4s00"}
    params = OAuther.sign("post", "https://www.khanacademy.org/api/auth2/request_token", [{"oauth_callback", "http://localhost:4000/auth/khanacademy/callback"}], creds)
    #query_string = normalize params


    response = Tesla.request(method: :post, body: "", url: "https://www.khanacademy.org/api/auth2/request_token", query: params, headers: [{"content-type", "text/plain"}])

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
      raise "#{inspect (key)} missing from config :ueberauth, Ueberauth.Strategy.KhanAcademy"
    end
    config
  end
  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.KhanAcademy is not a keyword list, as expected"  end
end
