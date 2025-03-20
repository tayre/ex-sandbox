defmodule Game2048.ScoreStore do
  @moduledoc """
  Manages high scores using ETS (Erlang Term Storage).
  """
  use GenServer

  @table_name :high_scores
  @default_scores_count 5
  @backup_file "priv/scores/high_scores.dat"

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get the highest scores in descending order.
  Returns a list of {score, timestamp} tuples.
  """
  def get_high_scores(count \\ @default_scores_count) do
    GenServer.call(__MODULE__, {:get_high_scores, count})
  end

  @doc """
  Submit a new score. If it's among the highest scores, it will be saved.
  Returns true if the score was high enough to be saved.
  """
  def submit_score(score) when is_integer(score) and score > 0 do
    GenServer.call(__MODULE__, {:submit_score, score})
  end

  # Server Callbacks

  @impl true
  def init(_) do
    # Create ETS table for high scores if it doesn't exist
    :ets.new(@table_name, [:named_table, :ordered_set, :protected])
    
    # Load high scores from file if it exists
    load_scores_from_file()

    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_high_scores, count}, _from, state) do
    scores = :ets.tab2list(@table_name)
             |> Enum.sort_by(fn {score, _timestamp} -> score end, :desc)
             |> Enum.take(count)
    
    {:reply, scores, state}
  end

  @impl true
  def handle_call({:submit_score, score}, _from, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    :ets.insert(@table_name, {score, timestamp})
    
    # Prune the table to keep only the top scores
    prune_scores()
    
    # Backup scores to file
    save_scores_to_file()
    
    is_high_score = is_high_score?(score)
    {:reply, is_high_score, state}
  end

  # Private functions

  defp is_high_score?(score) do
    count = @default_scores_count
    scores = :ets.tab2list(@table_name)
             |> Enum.sort_by(fn {score, _timestamp} -> score end, :desc)
             |> Enum.take(count)
    
    # Check if the score is among the top scores
    Enum.any?(scores, fn {saved_score, _timestamp} -> saved_score == score end)
  end

  defp prune_scores do
    # Keep only the top scores
    count = @default_scores_count
    all_scores = :ets.tab2list(@table_name)
                 |> Enum.sort_by(fn {score, _timestamp} -> score end, :desc)
    
    # If we have more scores than needed
    if length(all_scores) > count do
      # Delete the lower scores
      {keep, _delete} = Enum.split(all_scores, count)
      
      # Clear the table
      :ets.delete_all_objects(@table_name)
      
      # Re-insert only the top scores
      Enum.each(keep, fn score_entry -> :ets.insert(@table_name, score_entry) end)
    end
  end

  defp save_scores_to_file do
    # Ensure directory exists
    File.mkdir_p!(Path.dirname(@backup_file))
    
    # Get current scores
    scores = :ets.tab2list(@table_name)
    
    # Write to file using binary serialization
    scores_binary = :erlang.term_to_binary(scores)
    File.write!(@backup_file, scores_binary)
  end

  defp load_scores_from_file do
    case File.read(@backup_file) do
      {:ok, binary} ->
        try do
          scores = :erlang.binary_to_term(binary)
          Enum.each(scores, fn score_entry -> :ets.insert(@table_name, score_entry) end)
        rescue
          _error -> :ok  # File format might be corrupted, ignore
        end
      {:error, _reason} ->
        # File doesn't exist or can't be read, initialize with empty scores
        :ok
    end
  end
end