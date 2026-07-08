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

# ------------------------------------------------------------------------------

## Initiates a synchronized level transition across the connection. Server-only.
func change_scene(scene_path: String) -> void:
	pass

# ------------------------------------------------------------------------------

#region RPC Server-only
## [b]RPC Server-only:[/b] Dispatched by clients to update the server with local
## thread progress.
@rpc("any_peer", "call_remote", "reliable")
func _report_loading_progress(progress: float) -> void:
	pass


## [b]RPC Server-only:[/b] Notifies the server that local callbacks and asset
## loading are finished.
@rpc("any_peer", "call_remote", "reliable")
func _report_local_load_finished() -> void:
	pass
#endregion


#region RPC Server-only
## [b]RPC Client-only:[/b] Receives authoritative order to initiate local scene
## loading.
@rpc("call_remote", "authority", "reliable")
func _receive_scene_load_order(scene_path: String) -> void:
	pass


## [b]RPC Client-only:[/b] Sent by the server to synchronize progress
## dictionaries on clients.
@rpc("call_remote", "authority", "reliable")
func _update_peer_loading_status(peer_id: int, progress: float) -> void:
	pass


## [b]RPC Client-only:[/b] Commands clients to resume simulation, shift to
## PLAYING state (from [enum FSPeerManager.FSSessionState]), and spawn
## characters.
@rpc("call_remote", "authority", "reliable")
func _resume_network_simulation() -> void:
	pass
#endregion
