@tool
class_name FireSync
extends EditorPlugin
## Main EditorPlugin entry point for the FireSync multiplayer framework.
##
## Responsible for initializing Project Settings, exposing customization
## categories, and registering logical autoload singletons programmatically
## inside the editor tree.

# ------------------------------------------------------------------------------

## Setting path for the default ENet communication port.
const DEFAULT_PORT_SETTING_PATH: String = (
		"firesync/network/default_port")
## Setting path for the maximum allowed concurrent client connections.
const MAX_CONNECTIONS_SETTING_PATH: String = (
		"firesync/network/max_connections")
## Setting path for the client handshake authentication timeout limit.
const CONNECTION_TIMEOUT_SETTING_PATH: String = (
		"firesync/network/connection_timeout")
## Setting path for the maximum length of the Peer Name String.
const MAX_PEER_NAME_LENGTH_SETTING_PATH: String = (
		"firesync/network/max_peer_name_length")

## Default value for the default ENet communication port.
const DEFAULT_PORT_DEFAULT_VALUE: int = 10567
## Default value for the maximum allowed concurrent client connections.
const MAX_CONNECTIONS_DEFAULT_VALUE: int = 32
## Default value for the client handshake authentication timeout limit.
const CONNECTION_TIMEOUT_DEFAULT_VALUE: int = 10.0
## Default value for the maximum length of the Peer Name String.
const MAX_PEER_NAME_LENGTH_DEFAULT_VALUE: int = 32

# ------------------------------------------------------------------------------

func _enable_plugin() -> void:
	add_autoload_singleton(
			"FSPeerManager", "res://addons/firesync/core/peer_manager.gd")
	pass


func _disable_plugin() -> void:
	remove_autoload_singleton("FSPeerManager")
	pass


func _enter_tree() -> void:
	_register_setting(
			DEFAULT_PORT_SETTING_PATH, DEFAULT_PORT_DEFAULT_VALUE, TYPE_INT)
	_register_setting(
			MAX_CONNECTIONS_SETTING_PATH,
			MAX_CONNECTIONS_DEFAULT_VALUE, TYPE_INT)
	_register_setting(
			CONNECTION_TIMEOUT_SETTING_PATH,
			CONNECTION_TIMEOUT_DEFAULT_VALUE, TYPE_FLOAT)
	_register_setting(
			MAX_PEER_NAME_LENGTH_SETTING_PATH,
			MAX_PEER_NAME_LENGTH_DEFAULT_VALUE, TYPE_INT)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

# ------------------------------------------------------------------------------

## Helper method to write default settings into Project Settings.
func _register_setting(
		setting_name: String, default_value: Variant, type: int) -> void:
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, default_value)
	ProjectSettings.add_property_info({
		&"name": setting_name,
		&"type": type,
	})
	ProjectSettings.set_initial_value(setting_name, default_value)
	pass
