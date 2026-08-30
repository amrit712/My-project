extends Node
const NORAY_HOST := "tomfol.io"
const NORAY_PORT := 8890
const PORT := 7777
const MAX_PLAYERS := 8

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connected_to_server
signal connection_failed
signal server_disconnected


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	Noray.on_connect_nat.connect(_on_noray_connect)
	Noray.on_connect_relay.connect(_on_noray_connect)
func _on_noray_connect(address: String, port: int) -> Error:
	print("Noray gave us connection target: ", address, ":", port)

	return await _connect_to_noray_peer(address, port)
func _connect_to_noray_peer(address: String, port: int) -> Error:
	print("Performing Noray UDP handshake...")

	var udp := PacketPeerUDP.new()

	var error := udp.bind(Noray.local_port)

	if error != OK:
		print("UDP bind failed: ", error)
		return error

	udp.set_dest_address(address, port)

	error = await PacketHandshake.over_packet_peer(udp)

	udp.close()

	if error != OK:
		print("Noray handshake failed: ", error)
		return error

	print("Noray handshake successful.")

	var peer := ENetMultiplayerPeer.new()

	error = peer.create_client(
		address,
		port,
		0,
		0,
		0,
		Noray.local_port
	)

	if error != OK:
		print("ENet client creation failed: ", error)
		return error

	multiplayer.multiplayer_peer = peer

	print("ENet client started.")

	return OK
func host_game() -> Error:
	print("Starting Noray host setup...")

	var error := await connect_to_noray()

	if error != OK:
		return error

	error = await register_noray_host()

	if error != OK:
		return error

	var peer := ENetMultiplayerPeer.new()

	error = peer.create_server(
		Noray.local_port,
		MAX_PLAYERS
	)

	if error != OK:
		print("ENet server failed to start: ", error)
		return error

	multiplayer.multiplayer_peer = peer

	print("ENet server started on Noray port: ", Noray.local_port)
	print("Server peer ID: ", multiplayer.get_unique_id())
	print("PUBLIC OID: ", Noray.oid)

	return OK


func join_game(host_oid: String) -> Error:
	print("Starting Noray client setup...")

	var error: int = await connect_to_noray()

	if error != OK:
		return error

	print("Connected to Noray.")

	print("Registering client remote address...")

	error = await Noray.register_remote()

	if error != OK:
		print("Client register_remote failed: ", error)
		return error

	print("Client remote registration successful.")
	print("Client Noray local port: ", Noray.local_port)

	print("Requesting connection to host OID: ", host_oid)

	return join_noray_game(host_oid)


func leave_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)
	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	print("Connected to server.")

	test_message.rpc_id(1, "HELLO FROM CLIENT")

	connected_to_server.emit()


func _on_connection_failed() -> void:
	print("Connection failed.")
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("Server disconnected.")
	server_disconnected.emit()
@rpc("any_peer", "call_local", "reliable")
func test_message(message: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()

	# If this was called locally, there is no remote sender.
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()

	print("RPC MESSAGE from peer ", sender_id, ": ", message)
func connect_to_noray() -> Error:
	print("Connecting to Noray...")

	var error := await Noray.connect_to_host(
		NORAY_HOST,
		NORAY_PORT
	)

	if error != OK:
		print("Could not connect to Noray. Error: ", error)
		return error

	print("Connected to Noray.")

	return OK
func register_noray_host() -> Error:
	print("Registering as Noray host...")

	var error := Noray.register_host()

	if error != OK:
		print("Noray register_host failed: ", error)
		return error

	await Noray.on_pid

	print("Noray OID: ", Noray.oid)

	print("Registering remote address with Noray...")

	error = await Noray.register_remote()

	if error != OK:
		print("Noray register_remote failed: ", error)
		return error

	print("Noray remote registration successful.")
	print("Noray local port: ", Noray.local_port)

	return OK
	
func join_noray_game(host_oid: String) -> Error:
	print("Connecting to Noray host: ", host_oid)

	return Noray.connect_nat(host_oid)
