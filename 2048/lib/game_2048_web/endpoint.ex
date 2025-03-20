defmodule Game2048Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :game_2048

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_game_2048_key",
    signing_salt: "APatOTjh",
    same_site: "Lax",
    secure: false
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [
      connect_info: [session: @session_options], 
      check_origin: false,
      timeout: 45_000
    ],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static files from the root path
  plug Plug.Static,
    at: "/",
    from: :game_2048,
    gzip: false,
    only: Game2048Web.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug Game2048Web.Router
end
