class_name FSExtensionRegistry
extends Node
## A global registry for decoupling modular extension systems.
##
## The [b]FSExtensionRegistry[/b] singleton acts as a dynamic extension bus.
## Extension modules (e.g., chat, inventory) register themselves here on
## initialization, allowing other systems to find them without hardcoded paths
## or strict dependencies.[br][br]To create custom extensions, see
## [FSExtensionModule].

# ------------------------------------------------------------------------------

## Emitted when a new extension or extension module is registered successfully.
## [param extension_name] is the unique access identifier of the registered
## extension, and [param provider] is the extension Node itself (inside the scene
## tree).
signal extension_registered(extension_name: StringName, provider: Node)
## Emitted when an existing extension is unregistered or removed from the locator.
## [param extension_name] is the unique access identifier of the registered
## extension.
signal extension_unregistered(extension_name: StringName)

# ------------------------------------------------------------------------------

## Storage dictionary mapping unique StringName identifiers to FSExtensionModule
## instances (e.g. [code]{ extension_name ([StringName]): provider (
## [FSExtensionModule]) }[/code]).
var _extensions: Dictionary = {}

# ------------------------------------------------------------------------------

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass

# ------------------------------------------------------------------------------

## Registers a gameplay extension module instance ([param provider]) under a
## unique [StringName] key ([param extension_name]).
func register_extension(
		extension_name: StringName, provider: FSExtensionModule) -> void:
	pass


## Unregisters a extension from the locator. [param extension_name] is the unique
## access identifier for the extension.
func unregister_extension(extension_name: StringName) -> void:
	pass


## Retrieves a registered extension provider. Returns [code]null[/code] if not
## registered extension was found with identifier [param extension_name].
func get_extension(extension_name: StringName) -> Node:
	return null
