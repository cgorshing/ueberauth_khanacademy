defmodule UeberauthKhanAcademyTest do
  use ExUnit.Case
  use Plug.Test

  alias Plug.Session

  @session_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt",
    log: false,
    encrypt: false
  ]

  @secret String.duplicate("abcdef0123456789", 8)

  setup(%{path: path} = context) do
    Tesla.Mock.mock fn
      %{method: :post, url: "https://www.khanacademy.org/api/auth2/access_token"} ->
        %Tesla.Env{status: 200, body: "oauth_token=t4678922844962816&oauth_token_secret=wQGxdQvqmPMmVDNW"}

      %{method: :post, url: "https://www.khanacademy.org/api/auth2/request_token"} ->
        %Tesla.Env{status: 200, body: "hi!"}

      %{method: :get, url: "https://api.khanacademy.org/api/v1/user"} ->
        %Tesla.Env{status: 200, body: """
          {
            "name": "Testing Testing"
          }
        """}
    end

    conn =
      conn(:get, path)
      |> Map.put(:secret_key_base, @secret)
      |> Session.call(Session.init(@session_opts))
      |> fetch_session
      |> fetch_query_params
      |> put_session(:khanacademy_request, context[:request])
      |> Ueberauth.call(Ueberauth.init([]))
    [conn: conn]
  end

  @tag path: "/auth/khanacademy"
  test "handle request", %{conn: conn} do
    assert get_session(conn, :khanacademy_request) == "hi!"
  end

  #@tag path: "/auth/khanacademy/callback?oauth_verifier=VERIFER", request: %{oauth_token: "TOKEN", oauth_token_secret: "SECRET"}
  #test "handle callback", %{conn: %{assigns: %{ueberauth_auth: auth}}} do
    #assert %Ueberauth.Auth{} = auth
    #assert auth.extra.raw_info[:token] == %{
      #fullname: "FULL NAME",
      #oauth_token: "TOKEN",
      #oauth_token_secret: "SECRET",
      #user_nsid: "NSID",
      #username: "USERNAME"
    #}
  #end

  #@tag path: "/auth/khanacademy/callback?oauth_token=TOKEN&oauth_token_secret=SECRET&oauth_verifier=BAD_VERIFIER", request: %{oauth_token: "TOKEN", oauth_token_secret: "SECRET"}
  #test "handle callback with bad verifier", %{conn: %{assigns: %{ueberauth_failure: failure}}} do
    #assert failure.errors |> List.first |> Map.get(:message_key) == "access_error"
  #end

  @tag path: "/auth/khanacademy/callback"
  test "handle callback with no code", %{conn: %{assigns: assigns}} do
    assert %Ueberauth.Failure{} = assigns[:ueberauth_failure]
  end
end
