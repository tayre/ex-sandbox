defmodule Game2048.GameTest do
  use ExUnit.Case

  alias Game2048.Game

  describe "new/0" do
    test "creates a new game with an empty board and two random tiles" do
      game = Game.new()
      
      # Check board dimensions
      assert length(game.board) == 4
      assert Enum.all?(game.board, fn row -> length(row) == 4 end)
      
      # Check initial values
      assert game.score == 0
      assert game.game_over == false
      assert game.won == false
      
      # Check that exactly two tiles were added
      assert map_size(game.tiles) == 2
      
      # Count non-nil cells on the board
      non_nil_cells = 
        game.board
        |> List.flatten()
        |> Enum.count(& &1 != nil)
      
      assert non_nil_cells == 2
    end
  end

  describe "move/2" do
    test "moving in a direction merges tiles with the same value" do
      # Create a game with a controlled board for testing merges
      game = %Game{
        board: [
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [2, nil, nil, nil],
          [2, nil, nil, nil]
        ],
        score: 0,
        game_over: false,
        won: false,
        tiles: %{
          {2, 0} => %{id: "tile-1", value: 2, position: {2, 0}, merged_from: nil},
          {3, 0} => %{id: "tile-2", value: 2, position: {3, 0}, merged_from: nil}
        },
        next_id: 3
      }
      
      # Move up - should merge the two 2's into a 4
      moved_game = Game.move(game, :up)
      
      # Check that the board has changed correctly (ignoring the new random tile)
      # The top row should now have a 4
      assert Enum.at(moved_game.board, 0) |> Enum.at(0) == 4
      
      # Score should have increased by 4
      assert moved_game.score == 4
      
      # A new tile should have been added
      assert map_size(moved_game.tiles) == 2  # One merged tile plus one new tile
    end
    
    test "does not change the board for invalid moves" do
      # Create a game with a board where no tiles can move in the 'right' direction
      game = %Game{
        board: [
          [nil, nil, nil, 2],
          [nil, nil, nil, 4],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil]
        ],
        score: 0,
        game_over: false,
        won: false,
        tiles: %{
          {0, 3} => %{id: "tile-1", value: 2, position: {0, 3}, merged_from: nil},
          {1, 3} => %{id: "tile-2", value: 4, position: {1, 3}, merged_from: nil}
        },
        next_id: 3
      }
      
      # Move right - should not change the board
      moved_game = Game.move(game, :right)
      
      # The board should remain unchanged
      assert moved_game.board == game.board
      
      # Score should not change
      assert moved_game.score == game.score
      
      # No new tile should be added
      assert map_size(moved_game.tiles) == map_size(game.tiles)
    end
    
    test "wins the game when a 2048 tile is created" do
      # Create a game with a 1024 tile and a 1024 tile that will merge to 2048
      game = %Game{
        board: [
          [1024, 1024, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil]
        ],
        score: 0,
        game_over: false,
        won: false,
        tiles: %{
          {0, 0} => %{id: "tile-1", value: 1024, position: {0, 0}, merged_from: nil},
          {0, 1} => %{id: "tile-2", value: 1024, position: {0, 1}, merged_from: nil}
        },
        next_id: 3
      }
      
      # Move left - should merge the two 1024's into a 2048
      moved_game = Game.move(game, :left)
      
      # Check that the game is now in a won state
      assert moved_game.won == true
      
      # Score should have increased by 2048
      assert moved_game.score == 2048
    end
    
    test "recognizes game over when no moves are possible" do
      # Create a game where the board is full and no merges are possible
      full_board = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2]
      ]
      
      # Create tiles map matching the board
      tiles = %{
        {0, 0} => %{id: "tile-1", value: 2, position: {0, 0}, merged_from: nil},
        {0, 1} => %{id: "tile-2", value: 4, position: {0, 1}, merged_from: nil},
        {0, 2} => %{id: "tile-3", value: 2, position: {0, 2}, merged_from: nil},
        {0, 3} => %{id: "tile-4", value: 4, position: {0, 3}, merged_from: nil},
        {1, 0} => %{id: "tile-5", value: 4, position: {1, 0}, merged_from: nil},
        {1, 1} => %{id: "tile-6", value: 2, position: {1, 1}, merged_from: nil},
        {1, 2} => %{id: "tile-7", value: 4, position: {1, 2}, merged_from: nil},
        {1, 3} => %{id: "tile-8", value: 2, position: {1, 3}, merged_from: nil},
        {2, 0} => %{id: "tile-9", value: 2, position: {2, 0}, merged_from: nil},
        {2, 1} => %{id: "tile-10", value: 4, position: {2, 1}, merged_from: nil},
        {2, 2} => %{id: "tile-11", value: 2, position: {2, 2}, merged_from: nil},
        {2, 3} => %{id: "tile-12", value: 4, position: {2, 3}, merged_from: nil},
        {3, 0} => %{id: "tile-13", value: 4, position: {3, 0}, merged_from: nil},
        {3, 1} => %{id: "tile-14", value: 2, position: {3, 1}, merged_from: nil},
        {3, 2} => %{id: "tile-15", value: 4, position: {3, 2}, merged_from: nil},
        {3, 3} => %{id: "tile-16", value: 2, position: {3, 3}, merged_from: nil}
      }
      
      game = %Game{
        board: full_board,
        score: 0,
        game_over: false,
        won: false,
        tiles: tiles,
        next_id: 17
      }
      
      # Move in any direction should result in game over
      moved_game = Game.move(game, :left)
      
      # Check that the game is now in a game over state
      assert moved_game.game_over == true
      
      # The board should remain unchanged
      assert moved_game.board == game.board
    end
  end
  
  describe "add_random_tile/1" do
    test "adds a tile to an empty spot on the board" do
      # Create a game with a controlled board
      game = %Game{
        board: [
          [2, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil],
          [nil, nil, nil, nil]
        ],
        score: 0,
        game_over: false,
        won: false,
        tiles: %{
          {0, 0} => %{id: "tile-1", value: 2, position: {0, 0}, merged_from: nil}
        },
        next_id: 2
      }
      
      # Add a random tile
      game_with_new_tile = Game.add_random_tile(game)
      
      # Check that a new tile was added
      assert map_size(game_with_new_tile.tiles) == 2
      
      # Check that the next_id was incremented
      assert game_with_new_tile.next_id == 3
      
      # Count non-nil cells on the board
      non_nil_cells = 
        game_with_new_tile.board
        |> List.flatten()
        |> Enum.count(& &1 != nil)
      
      assert non_nil_cells == 2
    end
    
    test "does not change the board when no empty spots are available" do
      # Create a game with a completely full board
      full_board = [
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2, 4],
        [8, 16, 32, 64]
      ]
      
      # Create tiles map matching the board
      tiles = %{}
      tile_id = 1
      full_board_with_tiles = 
        for {row, row_idx} <- Enum.with_index(full_board), 
            {val, col_idx} <- Enum.with_index(row),
            into: tiles do
          {{row_idx, col_idx}, %{id: "tile-#{tile_id}", value: val, position: {row_idx, col_idx}, merged_from: nil}}
        end
      
      game = %Game{
        board: full_board,
        score: 0,
        game_over: false,
        won: false,
        tiles: full_board_with_tiles,
        next_id: 17
      }
      
      # Try to add a random tile
      game_with_new_tile = Game.add_random_tile(game)
      
      # The board should remain unchanged
      assert game_with_new_tile.board == game.board
      
      # The tiles should remain unchanged
      assert map_size(game_with_new_tile.tiles) == map_size(game.tiles)
      
      # The next_id should remain unchanged
      assert game_with_new_tile.next_id == game.next_id
    end
  end
end 