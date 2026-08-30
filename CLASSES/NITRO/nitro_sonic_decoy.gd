extends AbilityBase
class_name NitroSonicDecoy

# Ability 2 - Sonic Decoy
# Spawns a visual copy of your car that mirrors your live input (same
# throttle/steering you're pressing) for its lifetime. Enemies drive
# straight through it (it's a trigger, not a solid body) - touching it
# deals mild damage and applies a temporary slow + reveal debuff, then the
# decoy vanishes. It also vanishes on its own after decoy_lifetime.

@export var decoy_lifetime: float = 4.0
@export var spawn_forward_offset: float = 4.0
@export var decoy_move_speed: float = 22.0
@export var decoy_turn_speed: float = 2.0
@export var hit_damage: int = 10
@export var debuff_duration: float = 2.5
@export var slow_amount: float = 0.30
@export var unstable_steering_multiplier: float = 0.4   # how much steering control is reduced
@export var vulnerable_damage_bonus: float = 0.20
@export var reveal_duration: float = 5.0
@export var detonate_radius: float = 6.0
@export var detonate_slow_amount: float = 0.30
@export var detonate_slow_duration: float = 1.5

const WHEEL_PHYSICS_NODE_NAMES := ["BACK-LEFT", "BACK-RIGHT", "FRONT-LEFT", "FRONT-RIGHT"]

func _init():
	slot = Slot.ABILITY_2
	cooldown = 14.0
	mana_cost = 20.0

var _active_decoy: SonicDecoyBody = null

func activate(caster):
	var body_mount = caster.get_node_or_null("BodyMeshSlot")
	if body_mount == null or body_mount.get_child_count() == 0:
		push_warning("NitroSonicDecoy: caster has no body mesh to copy")
		return

	var mesh_clone = body_mount.get_child(0).duplicate()

	var decoy := SonicDecoyBody.new()
	decoy.owner_car = caster
	decoy.lifetime = decoy_lifetime
	decoy.move_speed = decoy_move_speed
	decoy.turn_speed = decoy_turn_speed

	caster.get_tree().current_scene.add_child(decoy)
	decoy.global_transform = caster.global_transform
	decoy.global_position += -caster.global_transform.basis.z * spawn_forward_offset

	decoy.add_child(mesh_clone)
	# Copy BodyMeshSlot's own transform, not a flat zero reset - if your
	# model needed a compensating rotation on BodyMeshSlot (common when a
	# model's forward-axis convention doesn't match Godot's default),
	# assuming zero throws that correction away and the clone ends up
	# rotated wrong.
	mesh_clone.transform = body_mount.transform

	_clone_wheels(caster, decoy)

	decoy.hit_by_enemy.connect(func(attacker): _on_decoy_hit(caster, attacker, decoy))

	_active_decoy = decoy
	print(caster.name, " deploys Sonic Decoy")

# Clones each wheel's visual mesh (found under the chassis's VehicleWheel3D
# nodes, inside the pivot WheelAttacher created) and places it at the same
# LOCAL offset on the decoy - but deliberately leaves them static, no spin
# driver attached. A sharp-eyed enemy noticing the wheels aren't turning is
# a nice emergent way to spot a decoy, not something to hide.
func _clone_wheels(caster: Node, decoy: Node3D):
	for wheel_name in WHEEL_PHYSICS_NODE_NAMES:
		var physics_wheel = caster.get_node_or_null(wheel_name)
		if physics_wheel == null:
			continue

		var pivot = null
		for child in physics_wheel.get_children():
			if str(child.name).ends_with("_Pivot"):
				pivot = child
				break
		if pivot == null:
			continue

		var wheel_clone = pivot.duplicate()

		wheel_clone.position = physics_wheel.position
		wheel_clone.rotation = pivot.rotation

enum DecoyDebuff { SLOW, UNSTABLE, VULNERABLE, BLINDED }

func _on_decoy_hit(caster, attacker, decoy):
	if attacker.has_node("Health"):
		attacker.get_node("Health").take_damage(hit_damage, caster)

	_apply_random_debuff(attacker)

	if attacker.has_node("StatusEffects"):
		attacker.get_node("StatusEffects").apply_status("revealed", reveal_duration, 1.0)

	print(caster.name, "'s decoy hit ", attacker.name)

	if is_instance_valid(decoy):
		decoy.queue_free()
	_active_decoy = null

func _apply_random_debuff(attacker):
	if not attacker.has_node("StatusEffects"):
		return
	var se = attacker.get_node("StatusEffects")
	var choice = DecoyDebuff.values()[randi() % DecoyDebuff.size()]

	match choice:
		DecoyDebuff.SLOW:
			se.apply_status("slow", debuff_duration, slow_amount)
			print(attacker.name, " hit the decoy -> SLOWED")
		DecoyDebuff.UNSTABLE:
			se.apply_status("unstable", debuff_duration, unstable_steering_multiplier)
			print(attacker.name, " hit the decoy -> UNSTABLE")
		DecoyDebuff.VULNERABLE:
			se.apply_status("vulnerable", debuff_duration, vulnerable_damage_bonus, true)
			print(attacker.name, " hit the decoy -> VULNERABLE")
		DecoyDebuff.BLINDED:
			se.apply_status("blinded", debuff_duration, 1.0)
			print(attacker.name, " hit the decoy -> BLINDED")

# Call this from your input handling when the player presses the
# detonate key/re-presses the ability while a decoy is out.
func detonate(caster) -> bool:
	if _active_decoy == null or !is_instance_valid(_active_decoy):
		return false

	var pos = _active_decoy.global_position
	for car in get_nearby_cars(caster, detonate_radius, false):
		if car.global_position.distance_to(pos) <= detonate_radius and car.has_node("StatusEffects"):
			car.get_node("StatusEffects").apply_status("slow", detonate_slow_duration, detonate_slow_amount)

	_active_decoy.queue_free()
	_active_decoy = null
	print(caster.name, " detonates Sonic Decoy")
	return true
