defmodule Game2048Web.ErrorJSONTest do
  use Game2048Web.ConnCase, async: true

  test "renders 404" do
    assert Game2048Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Game2048Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
