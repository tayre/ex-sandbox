defmodule Game2048.GameServer do
  @moduledoc """
  GenServer that manages game state and processes player moves.
  Now supports player-specific instances rather than a singleton.
  """
  use GenServer
  alias Game2048.{Game, ScoreStore}
  alias Phoenix.PubSub

  @pubsub Game2048.PubSub

  # Client API

  @doc """
  Starts the game supervisor - now deprecated in favor of start_player/1.
  """
  def start_link(_opts) do
    # For backward compatibility, this still exists but doesn't rely on a singleton
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Starts or retrieves a player-specific game server.
  """
  def start_player(player_id) do
    # Use Registry to track player-specific game processes
    name = {:via, Registry, {Game2048.GameRegistry, player_id}}
    
    case GenServer.start_link(__MODULE__, %{player_id: player_id}, name: name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  @doc """
  Gets the current game state for a specific player.
  """
  def get_state(game_pid) do
    GenServer.call(game_pid, :get_state)
  end

  @doc """
  Backwards compatibility - gets state from the default server if used.
  """
  def get_state do
    case Process.whereis(__MODULE__) do
      nil -> Game.new() # Fallback if server doesn't exist
      _pid -> GenServer.call(__MODULE__, :get_state)
    end
  end

  @doc """
  Gets the high scores - still global for backward compatibility.
  """
  def get_high_scores do
    ScoreStore.get_high_scores()
  end

  @doc """
  Gets the high scores for a specific player.
  """
  def get_player_high_scores(player_id) do
    ScoreStore.get_player_high_scores(player_id)
  end

  @doc """
  Starts a new game for a specific player.
  """
  def new_game(game_pid) do
    GenServer.call(game_pid, :new_game)
  end

  @doc """
  Backwards compatibility - starts a new game on the default server if used.
  """
  def new_game do
    case Process.whereis(__MODULE__) do
      nil -> Game.new() # Fallback if server doesn't exist
      _pid -> GenServer.call(__MODULE__, :new_game)
    end
  end

  @doc """
  Makes a move in the specified direction for a specific player.
  """
  def move(game_pid, direction) when direction in [:up, :down, :left, :right] do
    GenServer.call(game_pid, {:move, direction})
  end

  @doc """
  Backwards compatibility - makes a move on the default server if used.
  """
  def move(direction) when direction in [:up, :down, :left, :right] do
    case Process.whereis(__MODULE__) do
      nil -> Game.new() # Fallback if server doesn't exist
      _pid -> GenServer.call(__MODULE__, {:move, direction})
    end
  end

  @doc """
  Updates the game state directly for a specific player (used for debugging/testing).
  """
  def update_state(game_pid, game) do
    GenServer.call(game_pid, {:update_state, game})
  end

  @doc """
  Backwards compatibility - updates state on the default server if used.
  """
  def update_state(game) do
    case Process.whereis(__MODULE__) do
      nil -> game # Fallback if server doesn't exist
      _pid -> GenServer.call(__MODULE__, {:update_state, game})
    end
  end

  @doc """
  Submits a score for a specific player when the game is over.
  """
  def submit_player_score(player_id, score) when is_integer(score) and score > 0 do
    ScoreStore.submit_player_score(player_id, score)
  end

  @doc """
  Backwards compatibility - submits a score globally when the game is over.
  """
  def submit_score(score) when is_integer(score) and score > 0 do
    ScoreStore.submit_score(score)
  end

  # Server Callbacks

  @impl true
  def init(%{player_id: player_id}) do
    # Start with a new game, storing player_id
    {:ok, %{game: Game.new(), player_id: player_id}}
  end

  @impl true
  def init(_) do
    # For backward compatibility, initialize without player_id
    {:ok, %{game: Game.new(), player_id: nil}}
  end

  @impl true
  def handle_call(:get_state, _from, %{game: game} = state) do
    {:reply, game, state}
  end

  @impl true
  def handle_call(:new_game, _from, %{player_id: player_id} = state) do
    # If the game is over and has a score, save it
    if state.game.game_over and state.game.score > 0 do
      if player_id do
        ScoreStore.submit_player_score(player_id, state.game.score)
      else
        ScoreStore.submit_score(state.game.score) # Fallback for global scores
      end
    end
    
    new_game = Game.new()
    
    # Broadcast the new game state if there's a player_id
    if player_id do
      topic = "game:#{player_id}"
      PubSub.broadcast(@pubsub, topic, {:game_updated, new_game})
    end
    
    {:reply, new_game, %{state | game: new_game}}
  end

  @impl true
  def handle_call({:move, direction}, _from, %{game: game, player_id: player_id} = state) do
    # Don't process moves if the game is already over
    if game.game_over do
      {:reply, game, state}
    else
      new_game = Game.move(game, direction)
      
      # Only broadcast if the game state changed
      if new_game != game do
        # If the game just ended, save the score
        if new_game.game_over and not game.game_over and new_game.score > 0 do
          if player_id do
            is_high_score = ScoreStore.submit_player_score(player_id, new_game.score)
            
            # Broadcast the high score update if there's a player_id
            if is_high_score do
              topic = "game:#{player_id}"
              PubSub.broadcast(@pubsub, topic, {:new_high_score, new_game.score})
            end
          else
            # Fallback for global scores
            ScoreStore.submit_score(new_game.score)
          end
        end
        
        # Broadcast game state update if there's a player_id
        if player_id do
          topic = "game:#{player_id}"
          PubSub.broadcast(@pubsub, topic, {:game_updated, new_game})
        end
      end
      
      {:reply, new_game, %{state | game: new_game}}
    end
  end

  @impl true
  def handle_call({:update_state, new_game}, _from, %{player_id: player_id} = state) do
    # Broadcast the updated game state if there's a player_id
    if player_id do
      topic = "game:#{player_id}"
      PubSub.broadcast(@pubsub, topic, {:game_updated, new_game})
    end
    
    # Return and store the new game state
    {:reply, new_game, %{state | game: new_game}}
  end
end