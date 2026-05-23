extends Node

signal server_ready
signal server_lost

var DebugLoggerScript = preload("res://Utilities/Logger.gd")
var PacketManagerScript = preload("PacketManager.gd")
var InstanceManagerScript = preload("InstanceManager.gd")

var peer: ENetMultiplayerPeer
var is_server: bool = false
var local_peer_id: int = -1

var connected_clients: Dictionary = {}
var remote_players: Dictionary = {}
var remote_players_by_instance: Dictionary = {}

var hb_timer: Timer
var connected: bool = false
var handshake_sent: bool = false
var heartbeat_timer: float = 0.0

var logger: Node
var instance_manager: Node
var packet_manager: Node


# -------------------------
# INIT
# -------------------------
func _ready() -> void:
	# Initialize logger
	logger = DebugLoggerScript.new()
	add_child(logger)

	is_server = "--server" in OS.get_cmdline_args()

	if is_server:
		logger.info("Starting server...")
		start_server()

	hb_timer = Timer.new()
	hb_timer.wait_time = 0.1
	hb_timer.one_shot = false
	hb_timer.autostart = true
	hb_timer.timeout.connect(check_heartbeats)
	add_child(hb_timer)

	# Initialize instance manager
	instance_manager = InstanceManagerScript.new()
	instance_manager.setup(self, logger)
	add_child(instance_manager)
	
	# Initialize packet manager
	packet_manager = PacketManagerScript.new()
	packet_manager.setup(self, logger)
	add_child(packet_manager)


func _process(delta: float) -> void:
	if peer == null:
		return

	var status := peer.get_connection_status()

	if connected and status != MultiplayerPeer.CONNECTION_CONNECTED:
		handle_server_disconnect()
		return

	if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return

	peer.poll()

	# handshake
	if not handshake_sent and status == MultiplayerPeer.CONNECTION_CONNECTED:
		send_to_server({ "type": "c_handshake" })
		handshake_sent = true

	if connected:
		heartbeat_timer += delta
		if heartbeat_timer >= ServerConfig.HEARTBEAT_INTERVAL:
			heartbeat_timer = 0
			send_to_server({ "type": "c_heartbeat" })

	# packets
	while peer.get_available_packet_count() > 0:
		if is_server:
			var client_id = peer.get_packet_peer()
			var data = peer.get_var()
			packet_manager.handle_server_packet(client_id, data)
		else:
			var data = peer.get_var()
			packet_manager.handle_client_packet(data)


# -------------------------
# HELPERS
# -------------------------
func _send(data: Dictionary, target: int) -> void:
	if peer == null:
		return

	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return

	peer.set_target_peer(target)
	peer.put_var(data)
	peer.set_target_peer(0)


func send_to_server(data: Dictionary) -> void:
	if peer == null or is_server:
		return
	_send(data, 1)

func send_to_client(client_id: int, data: Dictionary) -> void:
	_send(data, client_id)


func broadcast_to_instance(map: String, instance: int, data: Dictionary):
	var key = "%s::%d" % [map, instance]

	if not remote_players_by_instance.has(key):
		return

	for client_id in remote_players_by_instance[key].keys():
		_send(data, client_id)

# -------------------------
# SERVER
# -------------------------
func start_server(port: int = -1) -> void:
	if port == -1:
		port = ServerConfig.DEFAULT_PORT

	peer = ENetMultiplayerPeer.new()

	var err := peer.create_server(port)
	if err:
		logger.error("Server failed: %s" % error_string(err))
		return

	logger.info("Server started on port %d" % port)
	is_server = true

# -------------------------
# HEARTBEAT / DISCONNECT
# -------------------------
func check_heartbeats():
	for client_id in connected_clients.keys().duplicate():
		connected_clients[client_id] += hb_timer.wait_time

		if connected_clients[client_id] > ServerConfig.HEARTBEAT_TIMEOUT:
			handle_disconnect(client_id, "timeout")


func full_cleanup_client(client_id: int):
	remote_players.erase(client_id)
	connected_clients.erase(client_id)

	for key in remote_players_by_instance.keys():
		if remote_players_by_instance[key].has(client_id):
			remote_players_by_instance[key].erase(client_id)


func handle_disconnect(client_id: int, reason: String) -> void:
	logger.info("Disconnect: %d - %s" % [client_id, reason])

	full_cleanup_client(client_id)


func handle_server_disconnect():
	if not connected and not handshake_sent:
		return

	connected = false
	handshake_sent = false
	heartbeat_timer = 0.0

	logger.warn("Lost connection to server")
	server_lost.emit()

	if peer:
		peer.close()
		peer = null


func disconnect_from_server() -> void:
	if peer == null:
		return

	logger.info("Manual disconnect requested")

	peer.close()
	peer = null

	handle_server_disconnect()

# -------------------------
# CLIENT
# -------------------------
func start_client(ip_address: String = "", port: int = -1) -> void:
	if ip_address == "":
		ip_address = ServerConfig.DEFAULT_SERVER_IP
	if port == -1:
		port = ServerConfig.DEFAULT_PORT
	
	peer = ENetMultiplayerPeer.new()

	var err := peer.create_client(ip_address, port)
	if err:
		logger.error("Client failed: %s" % error_string(err))
		return

	logger.info("Connecting to %s:%d..." % [ip_address, port])
