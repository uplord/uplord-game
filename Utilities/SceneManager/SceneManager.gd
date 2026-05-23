extends Node

@export var current_map: String = ""
@export var current_scene: String = ""
@export var current_instance: int = 1

var DebugLoggerScript = preload("res://Utilities/Logger.gd")

const DEFAULT_MAP := "StarterTown"
const DEFAULT_SCENE := "Scene1"

var logger: Node
var container: Node
var game_loader: Node
var selected_map: Node

var map_config: Dictionary = {}


# --------------------------------------------------
# SETUP
# --------------------------------------------------
func setup(scene_container: Node) -> void:
	logger = DebugLoggerScript.new()
	add_child(logger)

	container = scene_container
	current_map = DEFAULT_MAP
	current_scene = DEFAULT_SCENE

	_load_map_config()


# --------------------------------------------------
# MAP MANAGEMENT
# --------------------------------------------------
func unload_map() -> void:
	_clear_children(container)


func load_map() -> void:
	if not is_valid_map(current_map):
		logger.error("Invalid map: %s" % current_map)
		return

	_ensure_game_loader()

	if selected_map:
		selected_map.queue_free()
		selected_map = null

	var packed_map := _load_resource(_map_path(current_map))

	if not packed_map:
		return

	selected_map = packed_map.instantiate()
	game_loader.add_child(selected_map)

	load_scene(current_scene)


# --------------------------------------------------
# SCENES
# --------------------------------------------------
func load_scene(scene_name: String) -> void:
	if not selected_map:
		return
	
	if not is_valid_scene(current_map, scene_name):
		logger.error("Invalid scene %s in map %s" % [scene_name, current_map])
		return

	_clear_map_scenes()

	var scene_path := _scene_path(current_map, scene_name)
	var packed_scene := _load_resource(scene_path)

	if not packed_scene:
		logger.error("Failed loading scene: %s" % scene_path)
		return

	var scene = packed_scene.instantiate()
	scene.name = scene_name

	selected_map.add_child(scene)


func _clear_map_scenes() -> void:
	for child in selected_map.get_children():
		if child.name.begins_with("Scene"):
			child.queue_free()


# --------------------------------------------------
# LOADER
# --------------------------------------------------
func _ensure_game_loader() -> void:
	if game_loader:
		return

	var packed_loader := _load_resource("res://UI/GameLoader/GameLoader.tscn")
	if not packed_loader:
		logger.error("Failed loading game loader")
		return

	game_loader = packed_loader.instantiate()
	container.add_child(game_loader)

# --------------------------------------------------
# CONFIG LOADER
# --------------------------------------------------
func _load_map_config() -> void:
	var file := FileAccess.open("res://Config/maps.json", FileAccess.READ)

	if file == null:
		logger.error("Failed to load map config")
		return

	var data: Dictionary = JSON.parse_string(file.get_as_text())

	if typeof(data) != TYPE_DICTIONARY:
		logger.error("Invalid map config format")
		return

	map_config = data

# --------------------------------------------------
# HELPERS
# --------------------------------------------------
func _load_resource(path: String) -> Resource:
	var res := load(path)
	if res == null:
		logger.error("Failed loading resource: %s" % path)
	return res


func _map_path(map_name: String) -> String:
	return "res://Maps/%s/%s.tscn" % [map_name, map_name]


func _scene_path(map_name: String, scene_name: String) -> String:
	return "res://Maps/%s/Scenes/%s.tscn" % [map_name, scene_name]


func _clear_children(node: Node) -> void:
	if node == null:
		return

	for child in node.get_children():
		child.queue_free()


func is_valid_map(map_name: String) -> bool:
	return map_config.has(map_name)


func _get_scenes(map_name: String) -> Dictionary:
	return map_config.get(map_name, {}).get("scenes", {})


func scene_exists(map_name: String, scene_name: String) -> bool:
	return _get_scenes(map_name).has(scene_name)


func scene_is_unlocked(map_name: String, scene_name: String) -> bool:
	var scene_data = _get_scenes(map_name).get(scene_name, {})
	return not scene_data.get("locked", false)


func is_valid_scene(map_name: String, scene_name: String) -> bool:
	return scene_exists(map_name, scene_name) and scene_is_unlocked(map_name, scene_name)
