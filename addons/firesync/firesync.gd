@tool
extends EditorPlugin
## Main EditorPlugin entry point for the FireSync multiplayer framework.
##
## Responsible for initializing Project Settings, exposing customization
## categories, and registering logical autoload singletons programmatically
## inside the editor tree.

# ------------------------------------------------------------------------------

## Setting path for the default ENet communication port.
const SETTING_PORT := "firesync/network/default_port"
## Setting path for the maximum allowed concurrent client connections.
const SETTING_MAX_PEERS := "firesync/network/max_connections"
## Setting path for the client handshake authentication timeout limit.
const SETTING_TIMEOUT := "firesync/network/connection_timeout"

# ------------------------------------------------------------------------------

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

# ------------------------------------------------------------------------------

## Helper method to write default settings into Project Settings.
func _register_setting(
		setting_name: String, default_value: Variant, type: int) -> void:
	pass
