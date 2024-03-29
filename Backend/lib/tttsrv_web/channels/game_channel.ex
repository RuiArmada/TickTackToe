defmodule TttsrvWeb.GameChannel do
  alias TttsrvWeb.GameServer
  alias TttsrvWeb.GameManager
  use Phoenix.Channel
  require Logger

  def join("games:match:" <> game_id, params, socket) do
    GameManager.start_game(game_id)
    Logger.info("Joining game #{game_id}")

    name = Map.get(params, "name")

    case GameServer.add_player(game_id, socket.assigns.user_id, name) do
      {:ok, updated_game_state} ->
        Logger.info(inspect(updated_game_state), pretty: true)

        send(self(), {:game_state_updated, game_id})

        {:ok, assign(socket, :game, updated_game_state) |> assign(:game_id, game_id)}

      {:error, reason} ->
        Logger.info(inspect(reason), pretty: true)

        {:error, reason}
    end
  end

  ##############################################

  def handle_in("broadcast_message", %{"message" => message}, socket) do
    broadcast(socket, "game_message", %{message: message, sender_id: socket.assigns.user_id})
    {:noreply, socket}
  end

  ##############################################

  def handle_in("move", %{"x" => x, "y" => y}, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id

    case GameServer.move(game_id, user_id, x, y) do
      {:ok, updated_game_state, symbol} ->
        Logger.info(inspect(updated_game_state), pretty: true)

        send(self(), {:game_state_updated, game_id})
        broadcast(socket, "move_made", %{x: x, y: y, symbol: symbol})
        {:noreply, assign(socket, :game, updated_game_state)}

      {:error, reason} ->
        Logger.info(inspect(reason), pretty: true)

        {:reply, {:error, reason}, socket}
    end
  end

  def handle_in("surrender", _payload, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id

    case GameServer.surrender(game_id, user_id) do
      {:ok, updated_game_state} ->
        Logger.info(inspect(updated_game_state), pretty: true)

        send(self(), {:game_state_updated, game_id})
        {:noreply, assign(socket, :game, updated_game_state)}

      {:error, reason} ->
        Logger.info(inspect(reason), pretty: true)

        {:reply, {:error, reason}, socket}
    end
  end

  def handle_in("play_again", _payload, socket) do
    game_id = socket.assigns.game_id

    case GameServer.play_again(game_id) do
      {:ok, updated_game_state} ->
        Logger.info(inspect(updated_game_state), pretty: true)

        send(self(), {:game_state_updated, game_id})
        broadcast(socket, "play_again", %{game_state: updated_game_state})
        {:noreply, assign(socket, :game, updated_game_state)}

      {:error, reason} ->
        Logger.info(inspect(reason), pretty: true)

        {:reply, {:error, reason}, socket}
    end
  end

  def handle_in("request_game_state", _payload, socket) do
    game_id = socket.assigns.game_id
    game_state = GameServer.get_state(game_id)
    broadcast(socket, "game_state_sent", game_state)

    {:noreply, socket}
  end

  def handle_info({:game_state_updated, game_id}, socket) do
    if game_id == socket.assigns.game_id do
      game_state = GameServer.get_state(game_id)
      broadcast(socket, "game_state_sent", game_state)
    end

    {:noreply, socket}
  end
end
