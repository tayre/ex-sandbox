defmodule Game2048.Tile do
  @moduledoc """
  Handles tile operations for the 2048 game.
  """

  alias Game2048.Board
  alias Game2048.Game

  @new_tile_options [2, 4]
  @new_tile_weights [9, 1]
  @winning_tile Game.winning_tile()

  @type position :: {non_neg_integer(), non_neg_integer()}
  @type tile_info :: %{
    id: String.t(),
    value: non_neg_integer(),
    row: non_neg_integer(),
    col: non_neg_integer(),
    merged_from: [String.t()] | nil
  }
  @type tiles_map :: %{optional(position()) => tile_info()}

  @doc """
  Creates a new tile info map for a specific position and value.
  """
  @spec create_tile_info(non_neg_integer(), position(), non_neg_integer(), [String.t()] | nil) :: tile_info()
  def create_tile_info(value, {row, col}, id, merged_from \\ nil) do
    %{
      id: "tile-#{id}",
      value: value,
      row: row,
      col: col,
      merged_from: merged_from
    }
  end

  @doc """
  Randomly selects a value for a new tile (2 or 4) based on weights.
  """
  @spec random_tile_value() :: non_neg_integer()
  def random_tile_value do
    Enum.zip(@new_tile_options, @new_tile_weights)
    |> Enum.flat_map(fn {value, weight} -> List.duplicate(value, weight) end)
    |> Enum.random()
  end

  @doc """
  Adds a random tile to the board at an available position.
  """
  @spec add_random_tile(Board.board(), tiles_map(), non_neg_integer()) :: {Board.board(), tiles_map(), non_neg_integer()}
  def add_random_tile(board, tiles, next_id) do
    available_positions = Board.available_positions(board)

    if Enum.empty?(available_positions) do
      {board, tiles, next_id}
    else
      # Pick a random available position
      position = Enum.random(available_positions)
      {row, col} = position

      # Get a random value (2 or 4)
      value = random_tile_value()

      # Update the board with the new tile
      new_board = Board.put_tile(board, row, col, value)

      # Create a tile info for tracking
      tile_info = create_tile_info(value, position, next_id)

      # Update the tiles map
      new_tiles = Map.put(tiles, position, tile_info)

      {new_board, new_tiles, next_id + 1}
    end
  end

  @doc """
  Checks if a tile with the winning value exists on the board.
  """
  @spec has_winning_tile?(Board.board()) :: boolean()
  def has_winning_tile?(board) do
    board
    |> List.flatten()
    |> Enum.any?(&(&1 == @winning_tile))
  end

  @doc """
  Process a row for tile merging operations.
  """
  @spec process_row(list(Board.tile())) :: {list(Board.tile()), non_neg_integer()}
  def process_row(row) do
    # Remove nils and merge tiles
    row
    |> Enum.filter(&(&1 != nil))
    |> merge_tiles()
    |> then(fn {merged, score} ->
      # Add back nils to maintain row length
      {merged ++ List.duplicate(nil, length(row) - length(merged)), score}
    end)
  end

  @doc """
  Merges adjacent tiles with the same value.
  """
  @spec merge_tiles(list(Board.tile())) :: {list(Board.tile()), non_neg_integer()}
  def merge_tiles([]), do: {[], 0}
  def merge_tiles([x]), do: {[x], 0}
  def merge_tiles([x, x | rest]) do
    # Merge the two identical tiles
    {merged_rest, score_rest} = merge_tiles(rest)
    merged_value = x * 2
    {[merged_value | merged_rest], merged_value + score_rest}
  end
  def merge_tiles([x, y | rest]) do
    # Different values - keep both and continue
    {merged_rest, score_rest} = merge_tiles([y | rest])
    {[x | merged_rest], score_rest}
  end
end 