# 2048 Game

A 2048 game clone built with Elixir and Phoenix LiveView.

<img width="486" alt="2048_game" src="https://github.com/user-attachments/assets/24f843be-a71f-4e46-8c20-c4cf6f4102f6" />

## Run Locally

To start your Phoenix server:

1. Run `mix setup` to install and setup dependencies
2. Start Phoenix endpoint with `mix phx.server`
3. Visit [`localhost:4000`](http://localhost:4000) from your browser

## Overview

This is a clone of 2048 - a sliding tile puzzle game where the objective is to combine tiles with the same numbers to create a tile with the value 2048. 

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
