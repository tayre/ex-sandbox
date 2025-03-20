defmodule Game2048.Movement.Traversal do
  @moduledoc """
  Handles position traversal logic for the 2048 game movements.
  """

  alias Game2048.Board

  @type direction :: :up | :down | :left | :right
  @type position :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Gets the traversal order for positions based on direction.
  This ensures tiles are merged in the correct order.
  """
  @spec get_traversal_positions(direction()) :: [position()]
  def get_traversal_positions(direction) do
    rows = case direction do
      :up -> 0..3
      _ -> 0..3
    end
    
    cols = case direction do
      :left -> 0..3
      _ -> 0..3 
    end
    
    # For right and down movements, traverse from the opposite direction
    rows = if direction == :down, do: Enum.reverse(rows), else: rows
    cols = if direction == :right, do: Enum.reverse(cols), else: cols
    
    # Generate all position combinations based on the traversal order
    for row <- rows, col <- cols, do: {row, col}
  end

  @doc """
  Gets the next position in a given direction.
  """
  @spec get_next_position(position(), direction()) :: position()
  def get_next_position({row, col}, :up), do: {row - 1, col}
  def get_next_position({row, col}, :right), do: {row, col + 1}
  def get_next_position({row, col}, :down), do: {row + 1, col}
  def get_next_position({row, col}, :left), do: {row, col - 1}

  @doc """
  Finds the next position in a given direction.
  """
  @spec find_next_position(Board.board(), position(), direction()) :: position() | nil
  def find_next_position(_board, position, direction) do
    next_pos = get_next_position(position, direction)
    if Board.position_in_bounds?(next_pos) do
      next_pos
    else
      nil
    end
  end

  @doc """
  Finds the farthest position a tile can move in a given direction.
  """
  @spec find_farthest_position(Board.board(), position(), direction()) :: {position(), position() | nil}
  def find_farthest_position(board, position, direction) do
    find_farthest_position(board, position, direction, position)
  end

  @spec find_farthest_position(Board.board(), position(), direction(), position()) :: {position(), position() | nil}
  defp find_farthest_position(board, position, direction, current_farthest) do
    # Find the next position in the specified direction
    next_pos = find_next_position(board, current_farthest, direction)
    
    if next_pos != nil && Board.get_tile_at_position(board, next_pos) == nil do
      # If the next position is empty, we can potentially move further
      find_farthest_position(board, position, direction, next_pos)
    else
      # Return the farthest position we can move to and the next position (for merging check)
      {current_farthest, next_pos}
    end
  end
end 