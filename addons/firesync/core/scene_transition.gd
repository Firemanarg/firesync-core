class_name FSSceneTransition
extends Node
## Logical level loader enforcing a synchronized 3-Pillar loading sequence.
##
## This autoload handles background thread loaders and blocks spawning until all
## peers report ready, preventing desynchronization crashes.

# ------------------------------------------------------------------------------

## Emitted locally when starting a scene load process.
signal transition_started(scene_path: String)
## Emitted locally during background scene thread loading, returning values from
## [code]0.0[/code] to [code]1.0[/code].
signal local_load_progress(progress: float)
## Emitted locally when the client finishes loading resources into memory.
signal local_load_completed()
## Emitted globally when a remote peer's load progress changes.
signal peer_loading_progress_updated(peer_id: int, progress: float)
## Emitted globally when a specific remote peer reports complete load readiness.
signal peer_loading_completed(peer_id: int)
## Emitted on the server once all validated clients complete loading handshakes.
signal all_peers_synced()

# ------------------------------------------------------------------------------

const _PROGRESS_RPC_MIN_DIFFERENCE_TO_UPDATE: float = 0.01

## Optional callback invoked before level transitions start (e.g., UI fade out).
var pre_transition_callback: Callable
## Optional callback invoked after scene loading finishes but before reporting ready.
var post_transition_callback: Callable

## Active resource path pointing to the currently loaded scene file.
var current_scene_path: String = ""
## Authoritative loading log synced across clients:
## [code]{ peer_id: { "progress": float, "is_ready": bool } }[/code].
var loading_status: Dictionary = {}

## Authoritative tracker array checking peer IDs that report ready.
var _loaded_peers: Array[int] = []

## This property stores the last value that was sent to Host. This is used to
## calculate the difference and optimize requests, avoiding update progress on
## each frame
var _last_sent_progress: float = 0.0

# ------------------------------------------------------------------------------

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	var current_state: FSPeerManager.FSSessionState = (
			FSPeerManager.get_current_state())
	if not current_state == FSPeerManager.FSSessionState.SCENE_LOADING:
		return

	var progress_array: Array = []
	var status: ResourceLoader.ThreadLoadStatus = (
			ResourceLoader.load_threaded_get_status(
					current_scene_path, progress_array))

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var progress: float = (
					progress_array[0] if progress_array.size() > 0 else 0.0)
			var progress_difference: float = (
					clamp(progress - _last_sent_progress, 0.0, 1.0))
			if progress_difference >= _PROGRESS_RPC_MIN_DIFFERENCE_TO_UPDATE:
				_last_sent_progress = progress
				local_load_progress.emit(progress)
				_report_loading_progress.rpc(progress)

		ResourceLoader.THREAD_LOAD_LOADED:
			FSPeerManager._change_state(FSPeerManager.FSSessionState.SCENE_READY)
			_complete_local_loading()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error(
					"FireSync: Error while loading scene \"%s\"." % current_scene_path)
			FSPeerManager.self_disconnect()


func _physics_process(delta: float) -> void:
	pass

# ------------------------------------------------------------------------------

## Initiates a synchronized level transition across the connection. Server-only.
func change_scene(scene_path: String) -> void:
	const ALLOWED_STATES: Array[FSPeerManager.FSSessionState] = [
		 FSPeerManager.FSSessionState.LOBBY_ACTIVE,
		 FSPeerManager.FSSessionState.PLAYING,
	]

	if not multiplayer.is_server():
		push_error(
				"FireSync: Attempted to change scene, but local peer is not "
				+ "authority.")
		return

	var current_state: FSPeerManager.FSSessionState = (
			FSPeerManager.get_current_state())
	if not current_state in ALLOWED_STATES:
		push_error(
				"FireSync: Attempted to change scene, but another transition is"
				+ " in progress.")
		return

	_loaded_peers.clear()
	loading_status.clear()
	current_scene_path = scene_path

	FSPeerManager._change_state(FSPeerManager.FSSessionState.SCENE_TRANSITION)

	_receive_scene_load_order.rpc(scene_path)

# ------------------------------------------------------------------------------

#region RPC Server-only
## [b]RPC Server-only:[/b] Dispatched by clients to update the server with local
## thread progress.
@rpc("any_peer", "call_local", "reliable")
func _report_loading_progress(progress: float) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()

	if not loading_status.has(sender_id):
		loading_status[sender_id] = { &"progress": 0.0, &"is_ready": false }
	loading_status[sender_id][&"progress"] = progress

	_update_peer_loading_status.rpc(sender_id, progress)


## [b]RPC Server-only:[/b] Notifies the server that local callbacks and asset
## loading are finished.
@rpc("any_peer", "call_local", "reliable")
func _report_local_load_finished() -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()

	if not sender_id in _loaded_peers:
		_loaded_peers.append(sender_id)

	if not loading_status.has(sender_id):
		loading_status[sender_id] = { &"progress": 1.0, &"is_ready": true }

	peer_loading_completed.emit(sender_id)
	_notify_peer_loading_completed.rpc(sender_id)

	var all_loaded: bool = true
	for peer_id: int in FSPeerManager.active_peers.keys():
		if not peer_id in _loaded_peers:
			all_loaded = false
			break

	if all_loaded:
		all_peers_synced.emit()
		_resume_network_simulation.rpc()
#endregion


#region RPC Server-only
## [b]RPC Client-only:[/b] Receives authoritative order to initiate local scene
## loading.
@rpc("authority", "call_local", "reliable")
func _receive_scene_load_order(scene_path: String) -> void:
	FSPeerManager._change_state(FSPeerManager.FSSessionState.SCENE_TRANSITION)

	current_scene_path = scene_path
	_last_sent_progress = -1.0

	if pre_transition_callback.is_valid():
		await pre_transition_callback.call()

	if FSPeerManager.get_current_state() == FSPeerManager.FSSessionState.OFFLINE:
		push_error("FireSync: Disconnection detected during Scene Transition.")
		return

	var error: Error = ResourceLoader.load_threaded_request(scene_path, "", true)
	if not error == OK:
		push_error(
				"FireSync: Error while loading scene "
				+ ("\"%s\": %s." % [scene_path, error_string(error)]))
		FSPeerManager.self_disconnect()
		return

	FSPeerManager._change_state(FSPeerManager.FSSessionState.SCENE_LOADING)


## [b]RPC Client-only:[/b] Sent by the server to synchronize progress
## dictionaries on clients.
@rpc("authority", "call_remote", "reliable")
func _update_peer_loading_status(peer_id: int, progress: float) -> void:
	if not loading_status.has(peer_id):
		loading_status[peer_id] = { &"progress": 0.0, &"is_ready": false }
	loading_status[peer_id][&"progress"] = progress
	peer_loading_progress_updated.emit(peer_id, progress)


@rpc("authority", "call_remote", "reliable")
func _notify_peer_loading_completed(peer_id: int) -> void:
	if not loading_status.has(peer_id):
		loading_status[peer_id] = { &"progress": 1.0, &"is_ready": true }
	loading_status[peer_id][&"is_ready"] = true
	peer_loading_completed.emit(peer_id)


## [b]RPC Client-only:[/b] Commands clients to resume simulation, shift to
## PLAYING state (from [enum FSPeerManager.FSSessionState]), and spawn
## characters.
@rpc("authority", "call_local", "reliable")
func _resume_network_simulation() -> void:
	FSPeerManager._change_state(FSPeerManager.FSSessionState.PLAYING)
#endregion


func _complete_local_loading() -> void:
	var loaded_scene: PackedScene = (
			ResourceLoader.load_threaded_get(current_scene_path))
	if not loaded_scene:
		push_error(
				"FireSync: Failed to retrieve scene \"%s\"." % current_scene_path)
		FSPeerManager.self_disconnect()

	get_tree().change_scene_to_packed(loaded_scene)

	local_load_completed.emit()

	if post_transition_callback.is_valid():
		await post_transition_callback.call()

	_report_local_load_finished.rpc()
