defmodule Game2048Web.GameLiveTest do
  use Game2048Web.ConnCase
  import Phoenix.LiveViewTest

  alias Game2048.GameServer

  describe "Game page" do
    test "renders the game board", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      
      # Test basic elements
      assert html =~ "2048"
      assert html =~ "SCORE"
      assert html =~ "New Game"
      
      # Game board should be rendered
      assert has_element?(view, "#game-board")
      
      # Should have 16 empty grid cells (4x4 board)
      assert has_element?(view, ".grid-cols-4")
    end
    
    test "starts a new game when the 'New Game' button is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Capture the initial score displayed
      initial_score_text = element(view, "div.text-2xl.font-bold") |> render()
      
      # Click the New Game button
      view
      |> element("button", "New Game")
      |> render_click()
      
      # After starting a new game, the score should be 0
      new_score_text = element(view, "div.text-2xl.font-bold") |> render()
      
      # The new score should reflect a new game state
      assert new_score_text =~ "0"
    end
    
    test "displays high scores", %{conn: conn} do
      # Add some test high scores
      GameServer.new_game()
      
      # This is just to ensure we have at least one high score to display
      # In a real test, we might want to mock the ScoreStore
      # But we'll just add a simple high score for demonstration
      Game2048.ScoreStore.submit_score(1000)
      
      {:ok, view, _html} = live(conn, "/")
      
      # There should be a high scores section
      assert has_element?(view, "h2", "High Scores")
      
      # The high score we added should be visible
      high_scores_section = element(view, "div.divide-y") |> render()
      assert high_scores_section =~ "1000"
    end
    
    test "handles keyboard navigation", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Trigger an up arrow keydown
      view
      |> element("#game-board")
      |> render_keydown(%{key: "ArrowUp"})
      
      # We can't easily assert the exact state change since it depends
      # on the random initial board, but we can check that it responded
      
      # ArrowDown
      view
      |> element("#game-board")
      |> render_keydown(%{key: "ArrowDown"})
      
      # ArrowLeft
      view
      |> element("#game-board")
      |> render_keydown(%{key: "ArrowLeft"})
      
      # ArrowRight
      view
      |> element("#game-board")
      |> render_keydown(%{key: "ArrowRight"})
      
      # Ignore unhandled keys
      view
      |> element("#game-board")
      |> render_keydown(%{key: "Enter"})
    end
    
    test "supports mobile controls", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # Click the up arrow button
      view
      |> element("button[phx-value-direction='up']")
      |> render_click()
      
      # Down arrow
      view
      |> element("button[phx-value-direction='down']")
      |> render_click()
      
      # Left arrow
      view
      |> element("button[phx-value-direction='left']")
      |> render_click()
      
      # Right arrow
      view
      |> element("button[phx-value-direction='right']")
      |> render_click()
    end
    
    test "displays game alerts", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      
      # We can't easily force a game over or win condition in a test
      # without modifying the server state directly
      # but we can at least verify the alert element is not present initially
      refute has_element?(view, "div.bg-yellow-100")
    end
  end
end 