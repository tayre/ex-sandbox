defmodule Game2048.GameServer do
  @moduledoc """
  GenServer that manages game state and processes player moves.
  """
  use GenServer
  alias Game2048.{Game, ScoreStore}
  alias Phoenix.PubSub

  @pubsub Game2048.PubSub
  @topic "game:updates"

  # Client API

  @doc """
  Starts the game server.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Gets the current game state.
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Gets the high scores.
  """
  def get_high_scores do
    ScoreStore.get_high_scores()
  end

  @doc """
  Starts a new game.
  """
  def new_game do
    GenServer.call(__MODULE__, :new_game)
  end

  @doc """
  Makes a move in the specified direction.
  """
  def move(direction) when direction in [:up, :down, :left, :right] do
    GenServer.call(__MODULE__, {:move, direction})
  end

  @doc """
  Updates the game state directly (used for debugging/testing).
  """
  def update_state(game) do
    GenServer.call(__MODULE__, {:update_state, game})
  end

  @doc """
  Submits a score when the game is over.
  """
  def submit_score(score) when is_integer(score) and score > 0 do
    ScoreStore.submit_score(score)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    # Start with a new game
    {:ok, Game.new()}
  end

  @impl true
  def handle_call(:get_state, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call(:new_game, _from, game) do
    # If the game is over and has a score, save it
    if game.game_over and game.score > 0 do
      ScoreStore.submit_score(game.score)
    end
    
    new_game = Game.new()
    # Broadcast the new game state
    PubSub.broadcast(@pubsub, @topic, {:game_updated, new_game})
    {:reply, new_game, new_game}
  end

  @impl true
  def handle_call({:move, direction}, _from, game) do
    # Don't process moves if the game is already over
    if game.game_over do
      {:reply, game, game}
    else
      new_game = Game.move(game, direction)
      
      # Only broadcast if the game state changed
      if new_game != game do
        # If the game just ended, save the score
        if new_game.game_over and not game.game_over and new_game.score > 0 do
          is_high_score = ScoreStore.submit_score(new_game.score)
          
          # Broadcast the high score update
          if is_high_score do
            PubSub.broadcast(@pubsub, @topic, {:new_high_score, new_game.score})
          end
        end
        
        # Broadcast game state update
        PubSub.broadcast(@pubsub, @topic, {:game_updated, new_game})
      end
      
      {:reply, new_game, new_game}
    end
  end

  @impl true
  def handle_call({:update_state, new_game}, _from, _game) do
    # Broadcast the updated game state
    PubSub.broadcast(@pubsub, @topic, {:game_updated, new_game})
    
    # Return and store the new game state
    {:reply, new_game, new_game}
  end
end