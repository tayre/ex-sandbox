defmodule Game2048.ScoreStoreTest do
  use ExUnit.Case

  alias Game2048.ScoreStore
  alias Phoenix.PubSub

  # Set up a test PubSub to monitor broadcasts
  @pubsub Game2048.PubSub
  @topic "game:updates"

  setup do
    # Subscribe to broadcasts
    PubSub.subscribe(@pubsub, @topic)
    
    # Make sure ScoreStore is started
    start_supervised!(ScoreStore)
    
    # Clean up any existing scores to ensure test isolation
    File.rm_rf("priv/scores/high_scores_test.dat")
    
    :ok
  end

  describe "get_high_scores/1" do
    test "returns an empty list when no scores exist" do
      # When we start fresh, there should be no high scores
      assert [] = ScoreStore.get_high_scores()
    end
    
    test "returns the specified number of high scores" do
      # Add multiple scores
      ScoreStore.submit_score(100)
      ScoreStore.submit_score(200)
      ScoreStore.submit_score(300)
      ScoreStore.submit_score(400)
      ScoreStore.submit_score(500)
      ScoreStore.submit_score(600)
      
      # Get the top 3 scores
      high_scores = ScoreStore.get_high_scores(3)
      
      # Should return 3 scores in descending order
      assert length(high_scores) == 3
      
      scores = Enum.map(high_scores, fn {score, _timestamp} -> score end)
      assert scores == [600, 500, 400]
    end
  end
  
  describe "submit_score/1" do
    test "adds a score when it's the first one" do
      # Submit a score
      result = ScoreStore.submit_score(1000)
      
      # Should be added successfully
      assert result == true
      
      # Get high scores to verify
      high_scores = ScoreStore.get_high_scores()
      
      # Should have 1 score
      assert length(high_scores) == 1
      
      # First score should match what we submitted
      {score, _timestamp} = hd(high_scores)
      assert score == 1000
      
      # Should have received a high score notification
      assert_receive {:new_high_score, 1000}
    end
    
    test "adds a score when it's higher than existing scores" do
      # Add a few initial scores
      ScoreStore.submit_score(100)
      ScoreStore.submit_score(300)
      ScoreStore.submit_score(200)
      
      # Flush the messages we don't care about
      _ = flush_messages()
      
      # Add a higher score
      result = ScoreStore.submit_score(500)
      
      # Should be added successfully
      assert result == true
      
      # Get high scores to verify
      high_scores = ScoreStore.get_high_scores()
      
      # Should have 4 scores
      assert length(high_scores) == 4
      
      # First score should be our new high score
      {score, _timestamp} = hd(high_scores)
      assert score == 500
      
      # Should have received a high score notification
      assert_receive {:new_high_score, 500}
    end
    
    test "does not add a score when it's lower than all existing top scores" do
      # Submit the maximum number of high scores
      default_count = 5
      for i <- 1..default_count do
        ScoreStore.submit_score(i * 100)
      end
      
      # Flush the messages we don't care about
      _ = flush_messages()
      
      # Get the current high scores
      high_scores_before = ScoreStore.get_high_scores()
      
      # Submit a low score
      result = ScoreStore.submit_score(10)
      
      # Should not be added
      assert result == false
      
      # The high scores should remain unchanged
      high_scores_after = ScoreStore.get_high_scores()
      assert high_scores_before == high_scores_after
      
      # Should not have received a high score notification
      refute_receive {:new_high_score, _}
    end
    
    test "replaces the lowest score when a new score is higher" do
      # Submit the maximum number of high scores
      default_count = 5
      for i <- 1..default_count do
        ScoreStore.submit_score(i * 100)
      end
      
      # Flush the messages we don't care about
      _ = flush_messages()
      
      # Get the current high scores
      high_scores_before = ScoreStore.get_high_scores()
      
      # Submit a score better than the lowest but worse than the others
      result = ScoreStore.submit_score(150)
      
      # Should be added
      assert result == true
      
      # Get the new high scores
      high_scores_after = ScoreStore.get_high_scores()
      
      # Should still have the same number of scores
      assert length(high_scores_after) == length(high_scores_before)
      
      # The lowest score (100) should be replaced with 150
      low_score_before = high_scores_before |> Enum.map(fn {score, _} -> score end) |> Enum.min()
      low_score_after = high_scores_after |> Enum.map(fn {score, _} -> score end) |> Enum.min()
      
      assert low_score_before == 100
      assert low_score_after == 150
      
      # Should have received a high score notification
      assert_receive {:new_high_score, 150}
    end
  end
  
  # Helper function to drain the message queue
  defp flush_messages() do
    receive do
      msg -> [msg | flush_messages()]
    after
      0 -> []
    end
  end
end 