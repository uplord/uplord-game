extends Node

@onready var container = $SceneContainer

var map_loaded := false
var main_menu


func _ready() -> void:
	SceneManager.setup(container)
	ServerManager.server_lost.connect(_on_server_lost)
	ServerManager.server_ready.connect(_on_server_ready)

	show_main_menu()


func _on_server_ready():
	if map_loaded:
		return

	map_loaded = true
	SceneManager.unload_map()
	SceneManager.load_map()
	
	if main_menu and is_instance_valid(main_menu):
		main_menu.queue_free()
		main_menu = null

func _on_server_lost():
	map_loaded = false
	SceneManager.unload_map()
	show_main_menu()


func show_main_menu():
	if main_menu and is_instance_valid(main_menu):
		return

	var menu_scene = preload("res://UI/MainMenu/MainMenu.tscn")
	main_menu = menu_scene.instantiate()
	add_child(main_menu)
