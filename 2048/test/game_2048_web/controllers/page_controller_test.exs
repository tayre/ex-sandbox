defmodule Game2048Web.PageControllerTest do
  use Game2048Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    # We're now using LiveView, so the response should contain the LiveView setup
    assert html_response(conn, 200) =~ "phx-socket"
    # The page should display the game title
    assert html_response(conn, 200) =~ "2048"
  end
end
