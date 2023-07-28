defmodule StaasTest do
  use ExUnit.Case
  doctest Staas.Application

  test "get" do
    url = "http://localhost:4000/"
    {:ok, %HTTPoison.Response{status_code: status, body: body}} = HTTPoison.get(url)
    assert {status, body} == {200, "Welcome to StaS"}
  end

  test "send post with new list: [3,2,1]" do
    list = [3, 2, 1]
    {:ok, list_encoded} = Jason.encode(list)
    uuid = UUID.uuid5(nil, list_encoded)
    Redix.command(:redix, ["UNLINK", uuid])
    url = "http://localhost:4000/array"
    body = "{\"list\": [3,2,1]}"
    headers = [{"Content-type", "application/json"}]

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {200, "[1,2,3]\n#{uuid}"}
  end

  test "send post with existing list: [3,2,1]" do
    list = [3, 2, 1]
    {:ok, list_encoded} = Jason.encode(list)
    uuid = UUID.uuid5(nil, list_encoded)
    url = "http://localhost:4000/array"
    body = "{\"list\": [3,2,1]}"
    headers = [{"Content-type", "application/json"}]

    HTTPoison.post(url, body, headers, [])

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {200, "Array from cache: [1,2,3]\n#{uuid}"}
  end

  test "send post with invalid data type" do
    url = "http://localhost:4000/array"
    headers = [{"Content-type", "application/json"}]

    body = '{"list": true}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": null}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": "str"}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": "[3,2,1]"}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": {"a": 1, "b": 2}}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}
  end

  test "send post with invalid list" do
    url = "http://localhost:4000/array"
    headers = [{"Content-type", "application/json"}]

    body = '{"list": [3,2,"str"]}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": [true,5,6]}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": [[1,2],3,4]}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": ["1","3","2"]}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": ["6,5,4"]}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}

    body = '{"list": {"a": 1, "b": 2, "c": 3}}'

    {:ok, %HTTPoison.Response{status_code: status, body: body}} =
      HTTPoison.post(url, body, headers, [])

    assert {status, body} == {400, "Invalid array"}
  end

  test "get with non-existent uuid" do
    list = [3, 2, 1]
    {:ok, list_encoded} = Jason.encode(list)
    uuid = UUID.uuid5(nil, list_encoded)
    Redix.command(:redix, ["UNLINK", uuid])
    url = "http://localhost:4000/array/" <> "random_uuid"
    {:ok, %HTTPoison.Response{status_code: status, body: body}} = HTTPoison.get(url)
    assert {status, body} == {404, "No such uuid"}
  end

  test "get with existing uuid" do
    list = [3, 2, 1]
    {:ok, list_encoded} = Jason.encode(list)
    url = "http://localhost:4000/array"
    body = "{\"list\": [3,2,1]}"
    headers = [{"Content-type", "application/json"}]

    HTTPoison.post(url, body, headers, [])

    uuid = UUID.uuid5(nil, list_encoded)
    url = "http://localhost:4000/array/" <> uuid
    {:ok, %HTTPoison.Response{status_code: status, body: body}} = HTTPoison.get(url)
    assert {status, body} == {200, "[1,2,3]"}
  end
end
