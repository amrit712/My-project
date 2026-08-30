extends Node3D

@export var orb_scene: PackedScene

var current_orb: Node3D

func _ready() -> void:

	spawn_orb()
func spawn_orb() -> void:

	if current_orb != null:
		return

	if orb_scene == null:
		push_error("AbilityOrb scene is not assigned.")
		return

	current_orb = orb_scene.instantiate()

	add_child(current_orb)

	current_orb.position = Vector3.ZERO
