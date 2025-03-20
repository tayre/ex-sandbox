defmodule Game2048.Movement do
  @moduledoc """
  Handles movement operations for the 2048 game.
  This module delegates to specialized submodules for specific functionality.
  """

  alias Game2048.Movement.Traversal
  alias Game2048.Movement.Processor
  alias Game2048.Movement.Validator

  @type direction :: :up | :down | :left | :right
  @type position :: {non_neg_integer(), non_neg_integer()}
  @type board_size :: non_neg_integer()

  # Delegate traversal functions
  defdelegate get_traversal_positions(direction), to: Traversal
  defdelegate get_next_position(position, direction), to: Traversal
  defdelegate find_next_position(board, position, direction), to: Traversal
  defdelegate find_farthest_position(board, position, direction), to: Traversal
  
  # Delegate movement processing functions
  defdelegate process_move(board, tiles, score, next_id, positions, direction), to: Processor
  defdelegate move(board, tiles, score, next_id, direction), to: Processor
  
  # Delegate validation functions
  defdelegate moves_available?(board), to: Validator
end
