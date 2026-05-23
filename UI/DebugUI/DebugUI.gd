extends Node


func _on_button_pressed() -> void:
	ServerManager.disconnect_from_server()
