extends RigidBody3D

@export var item_name: String = "stone"
@export var amount: int = 1

@onready var pickup_area: Area3D = $Area3D

func set_mesh_and_material(mesh: Mesh):
	var mesh_instance = $MeshInstance3D
	mesh_instance.mesh = mesh


func _ready():
	pickup_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	var current = body
	while current:
		if current.is_in_group("player"):
			queue_free()  # Player picks up the item, so it disappears
			return
		current = current.get_parent()

# Set the correct mesh for the dropped item
