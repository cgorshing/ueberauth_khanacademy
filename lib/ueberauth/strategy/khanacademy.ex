defmodule Ueberauth.Strategy.KhanAcademy do
  require Logger

  @moduledoc """
  Flickr Strategy for Überauth.
  """

  use Ueberauth.Strategy, default_perms: nil

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  alias Ueberauth.Strategy.KhanAcademy.OAuth

  @doc """
  Handles initial request for Khan Academy authentication

  The initial entry point from ueberauth
  """
  def handle_request!(conn) do
    Logger.debug "+++ handle_request!"
    #IO.inspect conn

    result = OAuth.request_token!(redirect_uri: callback_url(conn))

    redirect_url = "https://www.khanacademy.org/api/auth2/authorize?" <> result

    conn
    |> put_session(:khanacademy_request, result)
    |> redirect!(redirect_url)
  end

  @doc """
  Handles the callback from Khan Academy
  """
  def handle_callback!(%Plug.Conn{params: %{"oauth_token" => oauth_token, "oauth_token_secret" => oauth_token_secret, "oauth_verifier" => oauth_verifier}} = conn) do
    IO.puts "+++ handle_callback! with params"

    #request = get_session(conn, :khan_academy_request)
    case OAuth.access_token(oauth_token, oauth_token_secret, oauth_verifier) do
      {:ok, access_token} -> fetch_user(conn, access_token)
      {:error, reason} -> set_errors!(conn, [error("access_error", reason)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    IO.puts "+++ handle_callback! with just conn"
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    IO.puts "+++ handle_cleanup!"
    conn
    |> put_private(:khanacademy_user_map, nil)
    |> put_private(:khanacademy_tokens, nil)
    |> put_session(:khanacademy_request_token, nil)
    |> put_session(:khanacademy_request_token_secret, nil)
  end

  @doc """
  Fetches the uid/kaid field from the response
  """
  def uid(conn) do
    IO.puts "+++ uid"
    conn.private.khanacademy_user_map["kaid"]
  end

  @doc """
  Includes the credentials from the Khan Academy response
  """
  def credentials(conn) do
    IO.puts "+++ credentials"
    #token = conn.private.flickr_access.oauth_token
    #secret = conn.private.flickr_access.oauth_token_secret
    #perms = get_session(conn, :flickr_perms)

    #%Credentials{token: token, secret: secret, scopes: [perms]}

    %Credentials{
      token: conn.private.khanacademy_tokens["oauth_token"],
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    IO.puts "+++ info(conn)"

    m = conn.private.khanacademy_user_map

    #TODO We really need the kaid
    %Ueberauth.Auth.Info{
      name: m["nickname"],
      nickname: m["username"],
      #email: m["email"] || Enum.find(user["emails"] || [], &(&1["primary"]))["email"],
      email: m["email"],
      #kaid: m["kaid"],
      image: m["avatar_url"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Flickr callback
  """
  def extra(conn) do
    IO.puts "+++ extra(conn)"
    %Extra{
      raw_info: %{
        token: conn.private.khanacademy_tokens["oauth_token"],
        user: conn.private.khanacademy_user_map
      }
    }
  end

  defp fetch_user(conn, tokens) do
    case OAuth.get_info(tokens) do
      {:ok, person} ->
        conn
        |> put_private(:khanacademy_user_map, person)
        |> put_private(:khanacademy_tokens, tokens)
      {:error, reason} ->
        set_errors!(conn, [error("get_info", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
