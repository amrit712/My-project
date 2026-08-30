extends AbilityBase
class_name NitroPhaseShift

# Ability 1 - Phase Shift
# 0.7s of intangibility: passes through enemy cars, projectiles, and arena
# hazards, but not walls. Deals no collision damage while phased. Fades the
# car's mesh transparency while active as visual feedback.

@export var phase_duration: float = 0.7
@export var phase_opacity: float = 0.6  # 0.0 = fully opaque, 1.0 = fully invisible
# Change this to match whichever physics layer your cars actually use.
const CARS_COLLISION_LAYER_BIT := 2

func _init():
	slot = Slot.ABILITY_1
	cooldown = 16.0
	mana_cost = 30.0

func activate(caster):
	if caster.has_node("StatusEffects"):
		caster.get_node("StatusEffects").apply_status("phased", phase_duration, 1.0)

	# Both LAYER and MASK need to change. Godot generates a collision if
	# EITHER body's mask matches the other's layer - clearing only our own
	# mask isn't enough, since the other car's mask still sees us sitting
	# on the "cars" layer and registers the hit from its own side
	# regardless of anything we changed. Clearing our layer too means no
	# other car's mask can detect us at all while phased.
	var was_on_cars_layer = caster.get_collision_layer_value(CARS_COLLISION_LAYER_BIT)
	var was_colliding_with_cars = caster.get_collision_mask_value(CARS_COLLISION_LAYER_BIT)

	caster.set_collision_layer_value(CARS_COLLISION_LAYER_BIT, false)
	caster.set_collision_mask_value(CARS_COLLISION_LAYER_BIT, false)

	# Fade every mesh on the car (body + wheels) using transparency, a
	# built-in GeometryInstance3D property MeshInstance3D inherits - no
	# material/shader editing needed, just a value between 0 and 1.
	var mesh_instances = _get_mesh_instances(caster)
	for mi in mesh_instances:
		mi.transparency = phase_opacity

	print(caster.name, " phase shifts")

	var timer = caster.get_tree().create_timer(phase_duration)
	timer.timeout.connect(func():
		if is_instance_valid(caster):
			caster.set_collision_layer_value(CARS_COLLISION_LAYER_BIT, was_on_cars_layer)
			caster.set_collision_mask_value(CARS_COLLISION_LAYER_BIT, was_colliding_with_cars)
			if caster.has_node("StatusEffects"):
				caster.get_node("StatusEffects").clear_status("phased")

		for mi in mesh_instances:
			if is_instance_valid(mi):
				mi.transparency = 0.0

		if is_instance_valid(caster):
			print(caster.name, " phase shift ends")
	)

func _get_mesh_instances(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_get_mesh_instances(child))
	return result
