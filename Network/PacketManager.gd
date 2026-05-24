extends Node

class_name PacketManager

var server_manager: Node
var logger: Node
var instance_manager: InstanceManager

# --------------------------------------------------
# SETUP
# --------------------------------------------------
func setup(sm: Node, logger_ref: Node):
	server_manager = sm
	logger = logger_ref
	instance_manager = server_manager.instance_manager


# --------------------------------------------------
# SERVER PACKETS
# --------------------------------------------------
func handle_server_packet(
	client_id: int,
	data: Dictionary
):
	match data.type:
		"c_handshake":
			server_manager.connected_clients[client_id] = 0.0

			logger.info(
				"Client connected: %d"
				% client_id
			)

			server_manager.send_to_client(
				client_id,
				{
					"type": "s_handshake_ack",
					"client_id": client_id
				}
			)

		"c_heartbeat":
			if server_manager.connected_clients.has(client_id):
				server_manager.connected_clients[client_id] = 0.0

		"c_spawn_player":
			_spawn_player(client_id)

		"c_move_player":
			_move_player(client_id, data)

		"c_teleport_player":
			_teleport_player(client_id, data)

		"c_request_sync":
			_request_sync(client_id)


# --------------------------------------------------
# SPAWN PLAYER
# --------------------------------------------------
func _spawn_player(client_id: int):
	pass


# --------------------------------------------------
# MOVE PLAYER
# --------------------------------------------------
func _move_player(
	client_id: int,
	data: Dictionary
):
	pass


# --------------------------------------------------
# TELEPORT PLAYER
# --------------------------------------------------
func _teleport_player(
	client_id: int,
	data: Dictionary
):
	pass


# --------------------------------------------------
# REQUEST SYNC
# --------------------------------------------------
func _request_sync(client_id: int):
	pass


# --------------------------------------------------
# CLIENT PACKETS
# --------------------------------------------------
func handle_client_packet(data: Dictionary):

	match data.type:
		"s_handshake_ack":
			server_manager.connected = true
			server_manager.local_peer_id = data.client_id

			server_manager.server_ready.emit()

			server_manager.send_to_server({
				"type": "c_spawn_player"
			})

		"s_spawn_player":
			pass

		"s_teleport_player":
			pass

		"s_request_sync":
			pass
