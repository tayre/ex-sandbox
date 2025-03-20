defmodule Game2048Web.GameLive do
  use Game2048Web, :live_view
  alias Game2048.GameServer
  alias Phoenix.PubSub

  @pubsub Game2048.PubSub
  @topic "game:updates"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to game updates
      PubSub.subscribe(@pubsub, @topic)
    end

    # Get the current game state and high scores
    game = GameServer.get_state()
    high_scores = GameServer.get_high_scores()
    
    # Extract all tiles from the game state for display
    tiles_list = extract_tiles_for_display(game)

    {:ok, assign(socket, 
      game: game, 
      alert: nil,
      high_scores: high_scores,
      last_direction: nil,
      highlight_score: false,
      tiles_list: tiles_list,
      just_moved: false
    )}
  end
  
  # Extract all tiles from the game state in a format suitable for display
  defp extract_tiles_for_display(game) do
    game.tiles
    |> Map.values()
    |> Enum.map(fn tile -> 
      cond do
        # Handle tiles with position tuple
        Map.has_key?(tile, :position) ->
          %{
            id: tile.id,
            value: tile.value,
            row: elem(tile.position, 0),
            col: elem(tile.position, 1),
            merged_from: tile.merged_from
          }
        
        # Handle tiles with direct row/col properties
        Map.has_key?(tile, :row) ->
          %{
            id: tile.id,
            value: tile.value,
            row: tile.row,
            col: tile.col,
            merged_from: tile.merged_from
          }
          
        # Fallback case
        true ->
          raise "Unexpected tile format: #{inspect(tile)}"
      end
    end)
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    game = GameServer.new_game()
    high_scores = GameServer.get_high_scores()
    
    # Extract tiles for display
    tiles_list = extract_tiles_for_display(game)
    
    {:noreply, assign(socket, 
      game: game, 
      alert: nil, 
      high_scores: high_scores,
      last_direction: nil,
      highlight_score: false,
      tiles_list: tiles_list,
      just_moved: false
    )}
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    direction = case key do
      "ArrowUp" -> :up
      "ArrowDown" -> :down
      "ArrowLeft" -> :left
      "ArrowRight" -> :right
      _ -> nil
    end

    if direction do
      # Save the old state to compare later
      old_game = socket.assigns.game
      
      # Make the move
      game = GameServer.move(direction)
      
      # Check for game state changes
      alert = cond do
        game.won -> "You win! Keep playing for a higher score."
        game.game_over -> "Game over! Press New Game to try again."
        true -> nil
      end
      
      # Only update if the board actually changed
      if game != old_game do
        # Extract tiles for display
        tiles_list = extract_tiles_for_display(game)
        
        # Set the just_moved flag to trigger animations
        {:noreply, assign(socket, 
          game: game, 
          alert: alert, 
          last_direction: direction,
          tiles_list: tiles_list,
          just_moved: true
        )}
      else
        {:noreply, assign(socket, game: game, alert: alert)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move", %{"direction" => direction}, socket) do
    dir = String.to_existing_atom(direction)
    
    # Save the old state to compare later
    old_game = socket.assigns.game
    
    # Make the move
    game = GameServer.move(dir)
    
    # Check for game state changes
    alert = cond do
      game.won -> "You win! Keep playing for a higher score."
      game.game_over -> "Game over! Press New Game to try again."
      true -> nil
    end
    
    # Only update if the board actually changed
    if game != old_game do
      # Extract tiles for display
      tiles_list = extract_tiles_for_display(game)
      
      # Set the just_moved flag to trigger animations
      {:noreply, assign(socket, 
        game: game, 
        alert: alert, 
        last_direction: dir,
        tiles_list: tiles_list,
        just_moved: true
      )}
    else
      {:noreply, assign(socket, game: game, alert: alert)}
    end
  end
  
  # Handle animations completion
  @impl true 
  def handle_event("animation_complete", _, socket) do
    {:noreply, assign(socket, just_moved: false)}
  end

  @impl true
  def handle_info({:game_updated, game}, socket) do
    # Handle game updates from the GameServer
    alert = cond do
      game.won -> "You win! Keep playing for a higher score."
      game.game_over -> "Game over! Press New Game to try again."
      true -> nil
    end
    
    # Extract tiles for display
    tiles_list = extract_tiles_for_display(game)
    
    {:noreply, assign(socket, 
      game: game, 
      alert: alert,
      tiles_list: tiles_list
    )}
  end
  
  @impl true
  def handle_info({:new_high_score, _score}, socket) do
    # Fetch updated high scores
    high_scores = GameServer.get_high_scores()
    
    # Set highlight flag to trigger animation
    socket = socket
             |> assign(high_scores: high_scores, highlight_score: true)
             
    # Schedule turning off the highlight
    Process.send_after(self(), :clear_highlight, 1500)
    
    {:noreply, socket}
  end

  @impl true
  def handle_info(:clear_highlight, socket) do
    {:noreply, assign(socket, highlight_score: false)}
  end

  # Helper functions for rendering
  
  defp tile_color(nil), do: "bg-gray-200"
  defp tile_color(2), do: "bg-gray-100 text-gray-800"
  defp tile_color(4), do: "bg-yellow-100 text-gray-800"
  defp tile_color(8), do: "bg-yellow-200 text-gray-800"
  defp tile_color(16), do: "bg-yellow-300 text-gray-800"
  defp tile_color(32), do: "bg-orange-300 text-white"
  defp tile_color(64), do: "bg-orange-400 text-white"
  defp tile_color(128), do: "bg-orange-500 text-white"
  defp tile_color(256), do: "bg-orange-600 text-white"
  defp tile_color(512), do: "bg-red-500 text-white"
  defp tile_color(1024), do: "bg-red-600 text-white"
  defp tile_color(2048), do: "bg-red-700 text-white"
  defp tile_color(_), do: "bg-purple-700 text-white" # For values beyond 2048
  
  defp font_size(nil), do: "text-2xl"
  defp font_size(val) when val < 100, do: "text-4xl font-bold"
  defp font_size(val) when val < 1000, do: "text-3xl font-bold"
  defp font_size(_), do: "text-2xl font-bold"
  
  # These are no longer needed as we use absolute positioning
  # defp animation_class(:up), do: "slide-up"
  # defp animation_class(:down), do: "slide-down"
  # defp animation_class(:left), do: "slide-left"
  # defp animation_class(:right), do: "slide-right"
  # defp animation_class(_), do: ""
  
  defp format_date(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime_utc, _} ->
        # Format the datetime in a short format without timezone conversion
        # Client-side JavaScript will handle the timezone conversion through browser's Date object
        datetime_str = Calendar.strftime(datetime_utc, "%Y-%m-%dT%H:%M:%S")
        "<span class='local-time' data-utc='#{datetime_str}'>#{Calendar.strftime(datetime_utc, "%m/%d %H:%M")}</span>"
      _ ->
        timestamp
    end
  end
  
  # Calculate the position style for a tile based on its row and column
  defp tile_position(row, col) do
    # Position the tile using the grid system only
    "grid-row: #{row + 1}; grid-column: #{col + 1};"
  end
  
  # Determine if a tile is new (just appeared this turn)
  defp is_new_tile?(tile_id, game) do
    # The tile ID format is "tile-X" where X is a number
    # Extract the number from the ID
    {tile_num, _} = tile_id 
                    |> String.replace("tile-", "") 
                    |> Integer.parse()
    
    # New game has initial tiles with IDs 1 and 2
    # For regular moves, only the latest tile (next_id - 1) is new
    case game.next_id do
      3 -> tile_num == 1 || tile_num == 2  # Special case for new game (2 initial tiles)
      _ -> tile_num == game.next_id - 1    # Regular case (latest tile only)
    end
  end
  
  # Determine if a tile was just merged
  defp is_merged_tile?(tile) do
    tile.merged_from != nil
  end
end