defmodule Game2048.Movement.Processor do
  @moduledoc """
  Processes movement operations for the 2048 game.
  """

  alias Game2048.Board
  alias Game2048.Tile
  alias Game2048.Movement.Traversal

  @type direction :: :up | :down | :left | :right
  @type position :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Processes a move in the given direction.
  """
  @spec process_move(Board.board(), Tile.tiles_map(), non_neg_integer(), non_neg_integer(), [position()], direction()) :: {Board.board(), Tile.tiles_map(), non_neg_integer(), non_neg_integer(), boolean()}
  def process_move(board, tiles, score, next_id, positions, direction) do
    # Process all positions in traversal order
    Enum.reduce(positions, {board, tiles, score, next_id, false}, fn position, {current_board, current_tiles, current_score, current_next_id, has_moved} ->
      # Get the current tile value at this position
      current_value = Board.get_tile_at_position(current_board, position)
      
      # Skip empty cells
      if current_value != nil do
        # Find the farthest position we can move to
        {farthest_pos, next_pos} = Traversal.find_farthest_position(current_board, position, direction)
        
        # Determine if we can merge with the next tile
        can_merge = next_pos != nil && 
                   Board.get_tile_at_position(current_board, next_pos) == current_value
        
        # Choose target position based on whether we can merge
        target_pos = if can_merge, do: next_pos, else: farthest_pos
        
        # Check if the tile actually moved
        tile_moved = position != target_pos
        
        # Only process if the tile is moving somewhere
        if tile_moved || can_merge do
          # Remove the tile from the original position
          {row, col} = position
          updated_board = Board.put_tile(current_board, row, col, nil)
          
          # Update score and board for the move
          {final_board, final_tiles, final_next_id, move_score} = if can_merge do
            # Merge with the target tile
            {target_row, target_col} = target_pos
            merged_value = current_value * 2
            
            # Update the board with the merged value
            merged_board = Board.put_tile(updated_board, target_row, target_col, merged_value)
            
            # Get the ids of the tiles being merged
            original_tile_info = Map.get(current_tiles, position, %{id: "tile-unknown"})
            target_tile_info = Map.get(current_tiles, target_pos, %{id: "tile-unknown"})
            
            # Remove the old tiles
            tiles_without_old = current_tiles
                              |> Map.delete(position)
                              |> Map.delete(target_pos)
            
            # Create merged tile info
            merged_tile_info = Tile.create_tile_info(
              merged_value,
              target_pos,
              current_next_id,
              [original_tile_info.id, target_tile_info.id]
            )
            
            # Add the new merged tile
            new_tiles = Map.put(tiles_without_old, target_pos, merged_tile_info)
            
            {merged_board, new_tiles, current_next_id + 1, merged_value}
          else
            # Just move without merging
            {target_row, target_col} = target_pos
            moved_board = Board.put_tile(updated_board, target_row, target_col, current_value)
            
            # Update the tile info for the moved tile
            original_tile_info = Map.get(current_tiles, position)
            moved_tile_info = %{original_tile_info | row: target_row, col: target_col}
            
            # Remove the old position and add the new one
            new_tiles = current_tiles
                     |> Map.delete(position)
                     |> Map.put(target_pos, moved_tile_info)
            
            {moved_board, new_tiles, current_next_id, 0}
          end
          
          {final_board, final_tiles, current_score + move_score, final_next_id, true}
        else
          # Tile didn't move
          {current_board, current_tiles, current_score, current_next_id, has_moved}
        end
      else
        # Empty cell - nothing to do
        {current_board, current_tiles, current_score, current_next_id, has_moved}
      end
    end)
  end

  @doc """
  Performs a move on the board in the given direction and returns updated game state.
  """
  @spec move(Board.board(), Tile.tiles_map(), non_neg_integer(), non_neg_integer(), direction()) :: {Board.board(), Tile.tiles_map(), non_neg_integer(), non_neg_integer(), boolean()}
  def move(board, tiles, score, next_id, direction) do
    # Get the traversal positions for this direction
    positions = Traversal.get_traversal_positions(direction)
    
    # Process the move
    process_move(board, tiles, score, next_id, positions, direction)
  end
end 