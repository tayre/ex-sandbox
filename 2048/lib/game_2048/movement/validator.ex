defmodule Game2048.Movement.Validator do
  @moduledoc """
  Validates if moves are available in the 2048 game.
  """

  alias Game2048.Board

  @doc """
  Checks if moves are possible in any direction.
  """
  @spec moves_available?(Board.board()) :: boolean()
  def moves_available?(board) do
    # Safely handle nil board or other invalid inputs
    case board do
      nil -> false
      [] -> false
      _ when not is_list(board) -> false
      _ -> 
        # Check for empty cells
        not Board.is_full?(board) ||
          # Check if adjacent cells have the same value (can be merged)
          Enum.any?(0..3, fn row ->
            Enum.any?(0..3, fn col ->
              current_value = safe_get_tile(board, row, col)
              # Check in all four directions
              has_same_neighbour?({row, col}, current_value, board)
            end)
          end)
    end
  end
  
  # Safely get a tile value, returning nil for any error
  defp safe_get_tile(board, row, col) do
    try do
      Board.get_tile(board, row, col)
    rescue
      # Handle any errors by returning nil
      _ -> nil
    end
  end
  
  # Checks if a position has a neighbour with the same value
  @spec has_same_neighbour?({integer(), integer()}, integer() | nil, Board.board()) :: boolean()
  defp has_same_neighbour?({row, col}, value, board) do
    value != nil && (
      # Check right - safely
      safe_get_tile(board, row, col+1) == value ||
      # Check down - safely
      safe_get_tile(board, row+1, col) == value ||
      # Check left - safely
      (col > 0 && safe_get_tile(board, row, col-1) == value) ||
      # Check up - safely
      (row > 0 && safe_get_tile(board, row-1, col) == value)
    )
  end
end 