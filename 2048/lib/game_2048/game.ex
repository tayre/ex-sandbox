defmodule Game2048.Game do
  @moduledoc """
  Main module that coordinates the 2048 game.
  Delegates to specialized modules for specific functionality.
  """

  alias Game2048.Board
  alias Game2048.Tile
  alias Game2048.Movement

  @winning_tile 2048

  # Expose the winning tile value for use by other modules
  def winning_tile, do: @winning_tile

  @type direction :: :up | :down | :left | :right
  @type position :: {non_neg_integer(), non_neg_integer()}

  @type t :: %__MODULE__{
    board: Board.board(),
    score: non_neg_integer(),
    game_over: boolean(),
    won: boolean(),
    tiles: Tile.tiles_map(),
    next_id: non_neg_integer()
  }

  defstruct board: nil, score: 0, game_over: false, won: false, tiles: %{}, next_id: 1

  @doc """
  Creates a new game with a fresh board and two random tiles.
  """
  @spec new() :: t()
  def new do
    # Create an empty board
    board = Board.new()
    
    # Start with an empty game
    %__MODULE__{board: board}
    |> add_random_tile()
    |> add_random_tile()
  end

  @doc """
  Adds a random tile to the game.
  """
  @spec add_random_tile(t()) :: t()
  def add_random_tile(%__MODULE__{board: board, tiles: tiles, next_id: next_id} = game) do
    {new_board, new_tiles, new_next_id} = Tile.add_random_tile(board, tiles, next_id)
    %{game | board: new_board, tiles: new_tiles, next_id: new_next_id}
  end

  @doc """
  Moves the tiles in the specified direction.
  """
  @spec move(t(), direction()) :: t()
  def move(%__MODULE__{game_over: true} = game, _direction), do: game
  def move(%__MODULE__{board: board, score: score, tiles: tiles, next_id: next_id} = game, direction) do
    # Process the move
    {new_board, new_tiles, new_score, new_next_id, moved} = 
      Movement.move(board, tiles, score, next_id, direction)
    
    # Only update if the tiles actually moved
    if moved do
      %{game | board: new_board, score: new_score, tiles: new_tiles, next_id: new_next_id}
      |> add_random_tile()
      |> check_win()
      |> check_game_over()
    else
      game
    end
  end

  @doc """
  Checks if the game has been won.
  """
  @spec check_win(t()) :: t()
  def check_win(%__MODULE__{board: board} = game) do
    # Check if any tile has reached the winning value
    if game.won || board |> List.flatten() |> Enum.any?(&(&1 == @winning_tile)) do
      %{game | won: true}
    else
      game
    end
  end

  @doc """
  Checks if the game is over (no more moves possible).
  """
  @spec check_game_over(t()) :: t()
  def check_game_over(%__MODULE__{board: board} = game) do
    # Game is over if the board is full and no moves are possible
    if not Movement.moves_available?(board) do
      %{game | game_over: true}
    else
      game
    end
  end
end