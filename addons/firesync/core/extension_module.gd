class_name FSExtensionModule
extends Node
## Abstract base class defining the standard contract and lifecycle for FireSync
## Extension Modules.
##
## All extension modules must inherit from this class.[br][br]It automates
## locator registration via tree entry signals and exposes overridable hooks
## for connection lifecycle event handling.

# ------------------------------------------------------------------------------

## Emitted when the extension module changes it's ready state.
signal extension_state_changed(extension_name: StringName, is_ready: bool)

# ------------------------------------------------------------------------------

## Unique identifier key used to register and locate this module.
@export var extension_name: StringName
## If [code]true[/code], registers this instance to FSExtensionRegistry on tree
## entry.
@export var auto_register: bool = true

## Tracks if the extension has parsed internal requirements and is ready.
var _is_initialized: bool = false

# ------------------------------------------------------------------------------

func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass

# ------------------------------------------------------------------------------

## [i]This is an overridable method.[/i][br][br][b]Virtual Hook:[/b] Triggered
## automatically upon registration to [FSExtensionRegistry].
func _on_extension_registered() -> void:
	pass


## [i]This is an overridable method.[/i][br][br][b]Virtual Hook:[/b] Triggered
## automatically upon removal from [FSExtensionRegistry].
func _on_extension_unregistered() -> void:
	pass


## [i]This is an overridable method.[/i][br][br][b]Virtual Hook:[/b] Triggered
## when a physical network socket finishes connection.
func _on_network_ready(is_server: bool) -> void:
	pass


## [i]This is an overridable method.[/i][br][br][b]Virtual Hook:[/b] Triggered
## when a new physical player joins the network session.
func _on_peer_connected(peer_id: int) -> void:
	pass


## [i]This is an overridable method.[/i][br][br][b]Virtual Hook:[/b] Triggered
## when a physical player disconnects from the session.
func _on_peer_disconnected(peer_id: int) -> void:
	pass

# ------------------------------------------------------------------------------

## Returns [code]true[/code] if the extension is initialized and ready for
## gameplay.
func is_extension_ready() -> bool:
	return false
