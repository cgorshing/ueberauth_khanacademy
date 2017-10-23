defmodule Ueberauth.Strategy.KhanAcademy.OAuthTest do
  use ExUnit.Case, async: true

  alias Ueberauth.Strategy.KhanAcademy.OAuth

  setup do
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

    Application.put_env :ueberauth, OAuth,
      client_id: "CONSUMER_KEY",
      client_secret: "CONSUMER_SECRET"
    :ok
  end

  test "access token" do
    {:ok, access_token} = OAuth.access_token("TOKEN", "SECRET", "VERIFIER")

    assert access_token ==
      %{"oauth_token" => "t4678922844962816", "oauth_token_secret" => "wQGxdQvqmPMmVDNW"}
  end

  test "access token!" do
    access_token = OAuth.access_token!("TOKEN", "SECRET", "VERIFIER")

    assert access_token ==
      %{"oauth_token" => "t4678922844962816", "oauth_token_secret" => "wQGxdQvqmPMmVDNW"}
  end

  test "get info" do
    tokens =
      %{"oauth_token" => "t4678922844962816", "oauth_token_secret" => "wQGxdQvqmPMmVDNW"}

    {:ok, info} = OAuth.get_info(tokens)

    assert info == %{
      "name" => "Testing Testing"
    }
  end

  test "request token" do
    {:ok, token} = OAuth.request_token(redirect_uri: "http://localhost/test")

    assert token == "hi!"
  end

  test "request token!" do
    token = OAuth.request_token!(redirect_uri: "http://localhost/test")

    assert token == "hi!"
  end
end
