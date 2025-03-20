defmodule Game2048.Board do
  @moduledoc """
  Handles board operations for the 2048 game.
  """

  alias Game2048.Constants

  @board_size Constants.board_size()

  @type tile :: non_neg_integer() | nil
  @type board :: [[tile()]]
  @type position :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Creates a new empty board.
  """
  @spec new() :: board()
  def new do
    List.duplicate(List.duplicate(nil, @board_size), @board_size)
  end

  @doc """
  Gets a tile at a specific position on the board.
  """
  @spec get_tile(board(), non_neg_integer(), non_neg_integer()) :: tile()
  def get_tile(board, row, col) do
    board |> Enum.at(row) |> Enum.at(col)
  end

  @doc """
  Gets a tile at a given position.
  """
  @spec get_tile_at_position(board(), position()) :: tile()
  def get_tile_at_position(board, {row, col}) do
    get_tile(board, row, col)
  end

  @doc """
  Puts a tile at a specific position on the board.
  """
  @spec put_tile(board(), non_neg_integer(), non_neg_integer(), tile()) :: board()
  def put_tile(board, row, col, value) do
    List.update_at(board, row, fn r ->
      List.replace_at(r, col, value)
    end)
  end

  @doc """
  Checks if the position is within the board boundaries.
  """
  @spec position_in_bounds?(position()) :: boolean()
  def position_in_bounds?({row, col}) do
    row >= 0 and row < @board_size and col >= 0 and col < @board_size
  end

  @doc """
  Transposes the board (rows become columns, columns become rows).
  """
  @spec transpose(board()) :: board()
  def transpose(board) do
    board
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  @doc """
  Gets all available positions on the board (positions with nil values).
  """
  @spec available_positions(board()) :: [position()]
  def available_positions(board) do
    for row <- 0..(@board_size - 1),
        col <- 0..(@board_size - 1),
        get_tile(board, row, col) == nil,
        do: {row, col}
  end

  @doc """
  Checks if the board is full (no nil values).
  """
  @spec is_full?(board()) :: boolean()
  def is_full?(board) do
    available_positions(board) == []
  end
end 