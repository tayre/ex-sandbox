# 2048 Game

A 2048 game clone built with Elixir and Phoenix LiveView.

Try it Live @ [http://2048.hal9k.ca/](http://2048.hal9k.ca/)

<img width="486" alt="2048_game" src="https://github.com/user-attachments/assets/24f843be-a71f-4e46-8c20-c4cf6f4102f6" />


## Run Locally

To start your Phoenix server:

1. Run `mix setup` to install and setup dependencies
2. Start Phoenix endpoint with `mix phx.server`
3. Visit [`localhost:4000`](http://localhost:4000) from your browser

## Overview

2048 is a sliding tile puzzle game where the objective is to combine tiles with the same numbers to create a tile with the value 2048. 

Features:
- Classic 2048 gameplay - merge tiles to reach 2048!
- Keyboard controls (arrow keys)
- Touch controls for mobile devices
- Smooth tile slide animations
- High score tracking system
- Real-time updates via Phoenix LiveView

## Project Structure

The project follows a modular architecture with clear separation of concerns:

```
lib/
├── game_2048/            # Core game logic
│   ├── application.ex    # Application supervisor
│   ├── board.ex          # Board operations and state
│   ├── constants.ex      # Shared constant values
│   ├── game.ex           # Main game coordination
│   ├── game_server.ex    # GenServer for game state
│   ├── movement/         # Movement-related modules
│   │   ├── processor.ex  # Processing tile movements
│   │   ├── traversal.ex  # Board traversal logic
│   │   └── validator.ex  # Movement validation
│   ├── movement.ex       # Movement operations
│   ├── score_store.ex    # High score storage
│   └── tile.ex           # Tile operations
└── game_2048_web/        # Web interface
    ├── components/       # LiveView components
    ├── controllers/      # Web controllers
    ├── live/             # LiveView modules
    └── templates/        # HTML templates
```

## Core Modules

- **Game**: Main module that coordinates the 2048 game, delegating to specialized modules
- **Board**: Handles board operations like creating a board, getting/setting tiles
- **Tile**: Manages tile operations such as creation, merging, and random tile generation
- **Movement**: Handles all aspects of moving tiles in different directions
- **ScoreStore**: Manages high score persistence and retrieval

## Elixir Features

### Pattern Matching

Elixir pattern matching to handle different game states and tile merging logic:

```elixir
# Pattern matching in function heads for tile merging
def merge_tiles([]), do: {[], 0}  # Empty list case
def merge_tiles([x]), do: {[x], 0}  # Single tile case
def merge_tiles([x, x | rest]) do  # Adjacent identical tiles case
  {merged_rest, score_rest} = merge_tiles(rest)
  {[x * 2 | merged_rest], x * 2 + score_rest}
end
def merge_tiles([x, y | rest]) do  # Non-matching tiles case
  {merged_rest, score_rest} = merge_tiles([y | rest])
  {[x | merged_rest], score_rest}
end
```

### Immutable Data Structures

The game leverages Elixir's immutable data structures for the game board:

- All board operations create new board states instead of modifying existing ones
- This prevents bugs from shared mutable state
- Makes game state snapshots and reversions trivial to implement

### GenServer for State Management

The game uses Elixir's GenServer behavior to manage the game state:

- Provides a clean API for game operations (new_game, move)
- Maintains game state between player actions
- Handles message passing between the game logic and the UI

### Module Attributes

Module attributes are used for configuration values and constants:

```elixir
@winning_tile 2048
@board_size 4
```

### Type Specifications

Uses Elixir's type specifications for better documentation and catch potential errors:

```elixir
@type tile :: non_neg_integer() | nil
@type board :: [[tile()]]
@type direction :: :up | :down | :left | :right
@type t :: %__MODULE__{
  board: board(),
  score: non_neg_integer(),
  game_over: boolean(),
  won: boolean()
}

@spec move(t(), direction()) :: t()
```

### Phoenix LiveView

The game uses Phoenix LiveView for a reactive, real-time UI:

- Real-time updates without page reloads
- Keyboard input handling
- Smooth animations with minimal JavaScript 
