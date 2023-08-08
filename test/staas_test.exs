defmodule StaasTest do
  use ExUnit.Case
  doctest Staas.Application

  @url "http://localhost:4000"

  describe "post" do
    test "send post with new list: [3,2,1]" do
      # Making sure that this list does not exist in Redis(a.k.a deleting it)
      list = [3, 2, 1]
      {:ok, list_encoded} = Jason.encode(list)
      uuid = UUID.uuid5(nil, list_encoded)
      Redix.command(:redix, ["UNLINK", uuid])

      url = @url <> "/array"
      params = %{list: [3, 2, 1]}
      jason_params = Jason.encode!(params)
      headers = [{"Content-type", "application/json"}]

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)

      assert status == 200, "Post was not successful #{status}"

      assert %{"list" => [1, 2, 3]} = jason_decoded,
             "Answers are different #{inspect(jason_decoded)}"
    end

    test "send post with existing list: [3,2,1]" do
      params = %{list: [3, 2, 1]}
      jason_params = Jason.encode!(params)

      url = @url <> "/array"
      headers = [{"Content-type", "application/json"}]

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)

      assert status == 200, "Post was not successful #{status}"

      assert %{"cached" => true} = jason_decoded,
             "Answer was not cached #{inspect(jason_decoded)}"

      assert %{"list" => [1, 2, 3]} = jason_decoded,
             "Answers are different #{inspect(jason_decoded)}"
    end

    test "send post with invalid data type" do
      url = @url <> "/array"
      headers = [{"Content-type", "application/json"}]

      params = %{list: "aaa"}
      jason_params = Jason.encode!(params)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)
      assert status == 400

      assert %{"error" => "Invalid array"} = jason_decoded

      params = %{list: nil}
      jason_params = Jason.encode!(params)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)
      assert status == 400

      assert %{"error" => "Invalid array"} = jason_decoded
    end

    test "send post with invalid list" do
      url = @url <> "/array"
      headers = [{"Content-type", "application/json"}]

      params = %{list: [3, 2, "a"]}
      jason_params = Jason.encode!(params)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)
      assert status == 400

      assert %{"error" => "Invalid array"} = jason_decoded

      params = %{list: [3, 2, true]}
      jason_params = Jason.encode!(params)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)
      assert status == 400

      assert %{"error" => "Invalid array"} = jason_decoded

      params = %{list: [3, 2, [1, 2]]}
      jason_params = Jason.encode!(params)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)
      assert status == 400

      assert %{"error" => "Invalid array"} = jason_decoded

      params = %{list: ["3", "2", "1"]}
      jason_params = Jason.encode!(params)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)
      assert status == 400

      assert %{"error" => "Invalid array"} = jason_decoded
    end
  end

  describe "get" do
    test "meeting panel" do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} = HTTPoison.get(@url)
      assert {status, body} == {200, "Welcome to StaaS"}
    end

    test "get with non-existent uuid" do
      list = [3, 2, 1]
      {:ok, list_encoded} = Jason.encode(list)
      uuid = UUID.uuid5(nil, list_encoded)

      # Making sure it does not exist
      Redix.command(:redix, ["UNLINK", uuid])

      url = @url <> "/array/" <> "#{uuid}"
      {:ok, %HTTPoison.Response{status_code: status, body: body}} = HTTPoison.get(url)

      jason_decoded_body = Jason.decode!(body)

      assert status == 404
      assert %{"error" => "No such uuid"} = jason_decoded_body
    end

    test "get with existing uuid" do
      list = [3, 2, 1]
      {:ok, list_encoded} = Jason.encode(list)
      uuid = UUID.uuid5(nil, list_encoded)
      Redix.command(:redix, ["UNLINK", uuid])

      url = @url <> "/array"
      params = %{list: [3, 2, 1]}
      jason_params = Jason.encode!(params)
      headers = [{"Content-type", "application/json"}]

      {:ok, %HTTPoison.Response{status_code: status, body: body}} =
        HTTPoison.post(url, jason_params, headers, [])

      jason_decoded = Jason.decode!(body)

      assert status == 200, "Post was not successful #{status}"

      assert %{"list" => [1, 2, 3]} = jason_decoded,
             "Answers are different #{inspect(jason_decoded)}"

      url = @url <> "/array/" <> "#{uuid}"
      {:ok, %HTTPoison.Response{status_code: status, body: body}} = HTTPoison.get(url)

      jason_decoded_body = Jason.decode!(body)

      assert status == 200
      assert %{"list" => [1, 2, 3]} = jason_decoded_body
    end
  end
end
