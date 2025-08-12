extends GridMap

var particle_scene = preload("res://scenes/block_break_particles.tscn")
var instance

@export var chunk_size_x: int = 64
@export var chunk_size_z: int = 64
@export var height_scale: int = 20

var base_noise := FastNoiseLite.new()
var hill_mask_noise := FastNoiseLite.new()

func _ready():
	randomize()

	# Setup base noise for hills
	base_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	base_noise.seed = randi()
	base_noise.frequency = 0.1

	# Setup hill mask noise to decide where hills appear
	hill_mask_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	hill_mask_noise.seed = randi()
	hill_mask_noise.frequency = 0.01  # low frequency for large zones

	clear()
	generate_terrain()
	generate_trees()

func generate_terrain():
	var base_height = height_scale / 4  # minimum height so it’s never completely flat
	var freq = 0.05  # controls hill size (lower = bigger hills)

	for x in range(chunk_size_x):
		for z in range(chunk_size_z):
			# Get noise at scaled coordinates for smooth hills everywhere
			var noise_val = base_noise.get_noise_2d(x * freq, z * freq)  # -1 to 1
			var mapped_val = (noise_val + 1) * 0.5  # 0..1

			# Map noise value to height range
			var height = int(lerp(base_height, height_scale, mapped_val))
			height = clamp(height, 1, height_scale)

			for y in range(height):
				var block_type = get_block_for_depth(y, height)
				set_cell_item(Vector3i(x, y, z), block_type)
				
func generate_trees():
	var tree_chance = 0.005
	const grass_block_id = 3
	for x in range(chunk_size_x):
		for z in range(chunk_size_z):
			if randf() < tree_chance:
				var y = get_highest_block_y(x, z)
				if y == -1:
					continue

				var block_below = get_cell_item(Vector3i(x, y, z))
				if block_below != grass_block_id:
					continue

				var trunk_height = randi() % 3 + 4  # 4 to 6 blocks tall
				place_tree(Vector3i(x, y + 1, z), trunk_height, 2)



				

func get_highest_block_y(x: int, z: int) -> int:
	for y in range(height_scale, -1, -1):
		if get_cell_item(Vector3i(x, y, z)) != -1:
			return y
	return -1

func place_tree(base_pos: Vector3i, trunk_height: int, leaves_radius: int) -> void:
	# Place trunk logs
	const log_block_id = 7
	const leaves_block_id = 4
	for i in range(trunk_height):
		set_cell_item(base_pos + Vector3i(0, i, 0), log_block_id)

	# Place leaves as a cube around the top
	var top_pos = base_pos + Vector3i(0, trunk_height, 0)
	for x_off in range(-leaves_radius, leaves_radius + 1):
		for y_off in range(-leaves_radius, leaves_radius + 1):
			for z_off in range(-leaves_radius, leaves_radius + 1):
				var leaf_pos = top_pos + Vector3i(x_off, y_off, z_off)
				# Optional: skip corners for rounder shape
				var dist = Vector3(x_off, y_off, z_off).length()
				if dist <= leaves_radius:
					# Avoid overwriting logs in trunk
					if get_cell_item(leaf_pos) == -1:
						set_cell_item(leaf_pos, leaves_block_id)




func get_block_for_depth(y: int, max_height: int) -> int:
	var grass_id = 3
	var dirt_id = 2
	var stone_id = 6

	if y == max_height - 1:
		return grass_id
	elif y > max_height - 4:
		return dirt_id
	else:
		return stone_id

# Your existing destroy_block() and place_block() functions go here...



func destroy_block(world_coordinate):
	var map_coordinate = local_to_map(to_local(world_coordinate))
	
	var block_index = get_cell_item(map_coordinate)
	if block_index == -1:
		return
	
	set_cell_item(map_coordinate, -1)
	
	var mesh = mesh_library.get_item_mesh(block_index)
	
	instance = particle_scene.instantiate()
	instance.position = map_to_local(map_coordinate)
	add_child(instance)
	instance.emitting = true
	
	var drop = preload("res://scenes/DroppedItem.tscn").instantiate()
	drop.item_name = "dirt"
	drop.amount = 1
	drop.set_mesh_and_material(mesh)
	
	var block_position = map_to_local(map_coordinate)
	
	get_tree().current_scene.add_child(drop)
	drop.global_transform.origin = block_position + Vector3(0, 1.5, 0)
	
	drop.apply_impulse(Vector3.ZERO, Vector3(randf() - 0.5, 0.8, randf() - 0.5) * 3.0)


func place_block(world_coordinate, block_index):
	var map_coordinate = local_to_map(to_local(world_coordinate))
	set_cell_item(map_coordinate, block_index)
