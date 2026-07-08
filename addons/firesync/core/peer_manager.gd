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
## [code]{ peer_id (int): { "nickname": String, "skin_id": int } }[/code]
var active_peers: Dictionary = {}
## [code]true[/code] if running as a headless server (no display/GPU).
var is_server_dedicated: bool = false

## Read-only active session state.[br][br]See [enum FSSessionState].
var _current_state: FSSessionState = FSSessionState.OFFLINE
## Reference to an abstract protocol handler (e.g., ENet).
var _network_provider: RefCounted

# ------------------------------------------------------------------------------

## Return the current state of a peer.[br][br]See [enum FSSessionState].
func get_current_state() -> FSSessionState:
	return FSSessionState.OFFLINE


## Commands the local peer to initialize as an authoritative session host.
func host_game(port: int = default_port, max_players: int = max_connections) -> Error:
	return OK


## Requests a connection to a remote server, passing local metadata for
## handshaking.
func join_game(ip: String, port: int = default_port, client_metadata: Dictionary = {}) -> Error:
	return OK


## Host-only. Kicks a peer from the server with a reason. (Server authoritative)
func kick_peer(peer_id: int, reason: String = "") -> void:
	pass

# ------------------------------------------------------------------------------

## Reads centralized properties dynamically on startup from Project Settings.
func _load_project_settings() -> void:
	pass


## Handle local machine state changes and emits matching state signals.
func _change_state(new_state: FSSessionState) -> void:
	pass


## Registers a connected client handshake with its validated metadata.
## (Server-side RPC)
@rpc("any_peer", "reliable")
func _register_client_handshake(metadata: Dictionary) -> void:
	pass
