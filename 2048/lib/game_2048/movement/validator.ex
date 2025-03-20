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
    # Check for empty cells
    not Board.is_full?(board) ||
      # Check if adjacent cells have the same value (can be merged)
      Enum.any?(0..3, fn row ->
        Enum.any?(0..3, fn col ->
          current_value = Board.get_tile(board, row, col)
          # Check in all four directions
          has_same_neighbour?({row, col}, current_value, board)
        end)
      end)
  end
  
  # Checks if a position has a neighbour with the same value
  @spec has_same_neighbour?({integer(), integer()}, integer() | nil, Board.board()) :: boolean()
  defp has_same_neighbour?({row, col}, value, board) do
    value != nil && (
      # Check right
      Board.get_tile(board, row, col+1) == value ||
      # Check down
      Board.get_tile(board, row+1, col) == value ||
      # Check left
      (col > 0 && Board.get_tile(board, row, col-1) == value) ||
      # Check up
      (row > 0 && Board.get_tile(board, row-1, col) == value)
    )
  end
end 