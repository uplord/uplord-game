extends Node

var DebugLoggerScript = preload("res://Utilities/Logger.gd")

var logger: Node
var container: Node

# --------------------------------------------------
# SETUP
# --------------------------------------------------
func setup(scene_container: Node):
	logger = DebugLoggerScript.new()
	add_child(logger)
	container = scene_container


func unload_map():
	if container == null:
		return

	for child in container.get_children():
		child.queue_free()

func load_map():
	if container == null:
		return

	var game_loader_path = "res://UI/GameLoader/GameLoader.tscn"
	var game_loader = load(game_loader_path)

	if game_loader == null:
		logger.error("Failed loading game loader: %s" % game_loader_path)
		return

	container.add_child(game_loader.instantiate())
