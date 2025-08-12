extends GridMap

var particle_scene = preload("res://scenes/block_break_particles.tscn")
var instance


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
	
	get_tree().current_scene.add_child(drop)  # Add to scene tree before positioning
	drop.global_transform.origin = block_position + Vector3(0, 1.5, 0)  # Now safe to set global_transform
	
	drop.apply_impulse(Vector3.ZERO, Vector3(randf() - 0.5, 0.8, randf() - 0.5) * 3.0)


func place_block(world_coordinate, block_index):
	var map_coordinate = local_to_map(to_local(world_coordinate))
	set_cell_item(map_coordinate, block_index)
