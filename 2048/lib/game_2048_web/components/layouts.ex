defmodule Game2048Web.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use Game2048Web, :controller` and
  `use Game2048Web, :live_view`.
  """
  use Game2048Web, :html

  embed_templates "layouts/*"
end
