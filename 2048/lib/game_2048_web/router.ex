defmodule Game2048Web.Router do
  use Game2048Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Game2048Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Game2048Web do
    pipe_through :browser

    live "/", GameLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Game2048Web do
  #   pipe_through :api
  # end
end
