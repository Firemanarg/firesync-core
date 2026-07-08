class_name FSNetworkActor
extends Node
## Plug-and-play component attached to CharacterBody2D/3D to handle authority
## and sync movement smoothly.
##
## This node has to be placed as a child node under a [CharacterBody2D] or
## [CharacterBody3D]. Decouples movement code from low-level interpolation and
## multiplayer sync config files.

# ------------------------------------------------------------------------------

## Emitted when multiplayer authority has been validated and injected.
signal authority_setup_completed(peer_id: int, is_local: bool)

# ------------------------------------------------------------------------------

## Sincronization asset configuration mapping properties to replicate.
@export var replication_config: SceneReplicationConfig
## Interpolation lerp smoothing factor applied toremote players to mask network
## latency.
@export var interpolation_speed: float = 15.0

## Reference to the multiplayer authority ID owning this body.
var authority_peer_id: int = -1

## Internal cached reference pointing to the parent physics body node.
var _parent_body: Node = null

# ------------------------------------------------------------------------------

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass

# ------------------------------------------------------------------------------

## Initializes the network actor, injecting authority.
func initialize_actor(peer_id: int) -> void:
	pass


## Return [code]true[/code] if the local client has authority over this physical
## actor.
func is_local_authority() -> bool:
	return false
