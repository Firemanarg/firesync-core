class_name FSPeerManager
extends Node
## Global Peer Manager that handles the physical network socket, peer metadata,
## and session lifecycle.
##
## This manager orchestrates low-level multiplayer connections, manages player
## metadata registers, and transits the global [enum FSSessionState] machine.

# ------------------------------------------------------------------------------

## Emitted when local client successfully initiates socket connection.
signal connection_established(my_peer_id: int)
## Emitted when client socket connection handshake fails.
signal connection_failed()
## Emitted on clients and server when a peer's metadata register has been
## validated.
signal peer_registered(peer_id: int, metadata: Dictionary)
## Emitted when a peer disconnects or is kicked from the active network.
signal peer_unregistered(peer_id: int)
## Emitted on clients when the connection to the server is lost.
signal server_disconnected()
## Emitted when the global game state transits to a new phase.
signal session_state_changed(new_state: FSSessionState)

# ------------------------------------------------------------------------------

## States representing individual phases of the global multiplayer session.
enum FSSessionState {
	OFFLINE,			## The game has no active socket or network simulation.
	HOST_STARTING,		## The server is establishing its socket port.
	CLIENT_CONNECTING,	## The client is performing low-level physical handshakes.
	LOBBY_ACTIVE,		## Peers are connected in a lobby, waiting for game start.
	SCENE_TRANSITION,	## Level load sequence initiated, physical replication frozen.
	SCENE_LOADING,		## The world scene is loading on background threads.
	SCENE_READY,		## Local resources loaded, waiting for slower peers.
	PLAYING,			## Spawners are active and gameplay is live.
}

## Local cache of default network port.[br][br]Setup this value on
## project settings ([code]firesync/network/default_port[/code]).
var default_port: int
## Local cache of max connection size.[br][br]Setup this value on
## project settings ([code]firesync/network/max_connections[/code]).
var max_connections: int
## Socket connection timeout in seconds.[br][br]Setup this value on
## project settings ([code]firesync/network/max_connections[/code]).
var connection_timeout: float

## Read-only authoritative player register formatted as:
## [code]{ peer_id (int): { &"name": String, ... (other metadata) } }[/code]
var active_peers: Dictionary = {}
## [code]true[/code] if running as a headless server (no display/GPU).
var is_server_dedicated: bool = false

## A validator method to prevent user of send invalid or malicious metadata.
## This method must have at least 2 parameters:
## [br][br]    [b]1.[/b] [param peer_id]: Index of the peer in the peers list. Index
## 1 is the host.[br]    [b]2.[/b] [param metadata]: A dictionary containing the
## peer metadata fields. This dictionary must be filtered and returned by the
## method.[br][br] If the validator returns an empty dictionary (invalid
## metadata), the peer is automatically disconnected (see [method kick_peer]).
var metadata_validator: Callable = Callable()
## Max length of the string that identifies each peer.[br][br]Setup this value
## on project settings ([code]firesync/network/max_peer_name_length[/code]).
var max_peer_name_length: int = 32

## Read-only active session state.[br][br]See [enum FSSessionState].
var _current_state: FSSessionState = FSSessionState.OFFLINE
## Reference to an abstract protocol handler (e.g., ENet).
var _network_provider: RefCounted

# ------------------------------------------------------------------------------

func _ready() -> void:
	_load_project_settings()
	is_server_dedicated = (
			OS.has_feature("dedicated_server")
			or DisplayServer.get_name() == "headless")
	if is_server_dedicated:
		host_game()
	multiplayer.peer_connected.connect(_on_engine_peer_connected)


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass

# ------------------------------------------------------------------------------

## Return the current state of a peer.[br][br]See [enum FSSessionState].
func get_current_state() -> FSSessionState:
	return _current_state


## Commands the local peer to initialize as an authoritative session host.
func host_game(
		port: int = default_port, max_players: int = max_connections,
		host_metadata: Dictionary = {}) -> Error:
	_change_state(FSSessionState.HOST_STARTING)

	if not _network_provider:
		_network_provider = ENetMultiplayerPeer.new()
	var err: Error = _network_provider.create_server(port, max_players)
	if not err == OK:
		_network_provider = null
		_change_state(FSSessionState.OFFLINE)
		push_error(
				"FireSync: Failed to start server on port"
				+ " %d. Error code: %s" % [port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = _network_provider

	var final_metadata: Dictionary = {}
	if is_server_dedicated:
		final_metadata[&"name"] = "Server"
	else:
		var host_name: String = host_metadata.get(&"name", "Host").strip_edges()
		if host_name.is_empty():
			host_name = "Host"
		host_metadata[&"name"] = (
				host_name.left(max_peer_name_length).strip_edges())
		final_metadata = host_metadata

		if metadata_validator.is_valid():
			final_metadata = await metadata_validator.call(1, final_metadata)
		if final_metadata.is_empty():
			_network_provider.close()
			_network_provider = null
			_change_state(FSSessionState.OFFLINE)
			push_error(
					"FireSync: The validator has rejected the metadata provided"
					+ " by the Host.")
			return ERR_CANT_CREATE

	active_peers[1] = final_metadata
	_change_state(FSSessionState.LOBBY_ACTIVE)
	if not is_server_dedicated:
		peer_registered.emit(1, final_metadata)
	return OK


## Requests a connection to a remote server, passing local metadata for
## handshaking.
func join_game(ip: String, port: int = default_port, client_metadata: Dictionary = {}) -> Error:
	return OK


## Host-only. Kicks a peer from the server with a reason. (Server authoritative)
func kick_peer(peer_id: int, reason: String = "") -> void:
	pass


## Injects a custom network provider to override the default ENet transport socket.
func set_network_provider(provider: RefCounted) -> void:
	if _current_state != FSSessionState.OFFLINE:
		push_error(
				"FireSync: Cannot change the network provider while a session "
				+ "is active.")
		return
	_network_provider = provider

# ------------------------------------------------------------------------------

## Reads centralized properties dynamically on startup from Project Settings.
func _load_project_settings() -> void:
	default_port = ProjectSettings.get_setting(
			FireSync.DEFAULT_PORT_SETTING_PATH,
			FireSync.DEFAULT_PORT_DEFAULT_VALUE)

	max_connections = ProjectSettings.get_setting(
			FireSync.MAX_CONNECTIONS_SETTING_PATH,
			FireSync.MAX_CONNECTIONS_DEFAULT_VALUE)

	connection_timeout = ProjectSettings.get_setting(
				FireSync.CONNECTION_TIMEOUT_SETTING_PATH,
				FireSync.CONNECTION_TIMEOUT_DEFAULT_VALUE)

	connection_timeout = ProjectSettings.get_setting(
				FireSync.MAX_PEER_NAME_LENGTH_SETTING_PATH,
				FireSync.MAX_PEER_NAME_LENGTH_DEFAULT_VALUE)


## Handle local machine state changes and emits matching state signals.
func _change_state(new_state: FSSessionState) -> void:
	if _current_state == new_state:
		return
	_current_state = new_state
	session_state_changed.emit(new_state)


## Registers a connected client handshake with its validated metadata.
## (Server-side RPC)
@rpc("any_peer", "reliable")
func _register_client_handshake(metadata: Dictionary) -> void:
	pass

# ------------------------------------------------------------------------------

func _on_engine_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		pass
