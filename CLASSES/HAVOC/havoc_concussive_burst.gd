extends AbilityBase
class_name HavocConcussiveBurst

# Ability 2 - Concussive Burst
# Quick side dash (direction from steering input, defaults right if
# neutral). Light collision damage, and applies "Concussed" to whoever it
# hits: camera shake + reduced steering responsiveness for 1.2s. No screen
# blur - this is a driving game, so the disruption is felt through
# handling, not vision.

@export var dash_impulse_speed: float = 12.0  # m/s of Δv
@export var dash_damage: int = 8
@export var concussed_duration: float = 1.2
@export var concussed_steering_multiplier: float = 0.5

func _init():
	slot = Slot.ABILITY_2
	cooldown = 11.0
	mana_cost = 30

func activate(caster):
	var steer_input = Input.get_axis("RIGHT", "LEFT") if caster.is_player else 0.0
	var side = 1.0 if steer_input < 0 else -1.0
	if abs(steer_input) < 0.05:
		side = 1.0

	var right = caster.global_transform.basis.x
	caster.apply_central_impulse(right * side * dash_impulse_speed * caster.mass)

	if caster.has_node("Camera3D/CameraShake"):
		caster.get_node("Camera3D/CameraShake").add_trauma(0.3)

	for body in caster.get_colliding_bodies():
		if body.is_in_group("cars") and body != caster:
			_apply_concussion(caster, body)

	print(caster.name, " uses Concussive Burst")

func _apply_concussion(caster, target):
	if target.has_node("Health"):
		target.get_node("Health").take_damage(dash_damage, caster)
	if target.has_node("StatusEffects"):
		target.get_node("StatusEffects").apply_status("concussed", concussed_duration, concussed_steering_multiplier)
	if target.is_player and target.has_node("Camera3D/CameraShake"):
		target.get_node("Camera3D/CameraShake").add_trauma(0.5)
