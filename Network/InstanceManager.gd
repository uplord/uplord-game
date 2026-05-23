extends Node

class_name InstanceManager

var server_manager: Node
var logger: Node

# map::instance -> [client_ids]
var instance_population := {}

# map::instance -> { client_id : spawn_index }
var used_spawn_ids := {}

# map::scene -> spawn positions
var spawn_points_cache := {}


# --------------------------------------------------
# SETUP
# --------------------------------------------------
func setup(sm: Node, logger_ref: Node):
	server_manager = sm
	logger = logger_ref


# --------------------------------------------------
# INSTANCE KEYS
# --------------------------------------------------
func get_instance_key(map: String, scene: String, instance: int) -> String:
	return "%s::%s::%d" % [map, scene, instance]


# --------------------------------------------------
# INSTANCE LIMITS
# --------------------------------------------------
func get_map_player_limit(map: String) -> int:
	var path = "res://Maps/%s/%s.tscn" % [
		map,
		map
	]

	var packed = load(path)

	if packed == null:
		return ServerConfig.INSTANCE_PLAYER_LIMIT

	var temp = packed.instantiate()

	var limit : int = ServerConfig.INSTANCE_PLAYER_LIMIT

	if "player_max" in temp:
		limit = temp.player_max

	temp.queue_free()

	return limit


func get_map_instance_population(
	map: String,
	instance: int
) -> int:
	var total := 0

	for key in instance_population.keys():

		var parts = key.split("::")

		if parts.size() < 3:
			continue

		var key_map = parts[0]
		var key_instance = int(parts[2])

		if key_map == map and key_instance == instance:
			total += instance_population[key].size()

	return total

# --------------------------------------------------
# FIND INSTANCE
# --------------------------------------------------
func find_available_instance(
	map: String,
	scene: String
) -> int:
	var limit = get_map_player_limit(map)

	for instance in range(
		1,
		ServerConfig.MAX_INSTANCES_PER_MAP + 1
	):

		var population = get_map_instance_population(
			map,
			instance
		)

		# INSTANCE HAS SPACE
		if population < limit:

			var key = get_instance_key(
				map,
				scene,
				instance
			)

			if not instance_population.has(key):
				instance_population[key] = []

			return instance

	logger.warn(
		"No available instances for map: %s"
		% map
	)

	return -1

# --------------------------------------------------
# INSTANCE PLAYERS
# --------------------------------------------------
func add_player_to_instance(
	client_id: int,
	map: String,
	scene: String,
	instance: int
):
	var key = get_instance_key(
		map,
		scene,
		instance
	)

	if not instance_population.has(key):
		instance_population[key] = []

	if not instance_population[key].has(client_id):
		instance_population[key].append(client_id)


func remove_player_from_instance(
	client_id: int,
	map: String,
	scene: String,
	instance: int
):
	var key = get_instance_key(
		map,
		scene,
		instance
	)

	if not instance_population.has(key):
		return

	instance_population[key].erase(client_id)

	if instance_population[key].is_empty():
		instance_population.erase(key)


func get_instance_players(
	map: String,
	scene: String,
	instance: int,
) -> Array:
	var key = get_instance_key(
		map,
		scene,
		instance,
	)

	return instance_population.get(key, [])


func get_instance_count(
	map: String,
	scene: String,
	instance: int
) -> int:
	return get_instance_players(
		map,
		scene,
		instance
	).size()


# --------------------------------------------------
# CLEANUP
# --------------------------------------------------
func clear_empty_instances():
	for key in instance_population.keys():

		if instance_population[key].is_empty():
			instance_population.erase(key)
