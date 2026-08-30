extends AbilityBase
class_name HavocScorchedEarth

# Ultimate - Scorched Earth
# Havoc immediately takes 20% max HP as self-damage. A fire ring expands
# to 15m radius over 2s, following Havoc's position for the first 1s
# before locking in place. Enemies inside: 25% slow + damage over time,
# and get marked Vulnerable via Thermal Amplifier.

@export var final_radius: float = 15.0
@export var expand_duration: float = 2.0
@export var follow_duration: float = 1.0
@export var self_damage_percent: float = 0.20
@export var slow_amount: float = 0.25
@export var damage_per_second: int = 10
@export var ring_lifetime: float = 6.0

func _init():
	slot = Slot.ULTIMATE
	cooldown = 60.0
	mana_cost = 100.0

func activate(caster):
	if caster.has_node("Health"):
		var h = caster.get_node("Health")
		h.take_damage(int(h.max_health * self_damage_percent))

	print(caster.name, " unleashes Scorched Earth")
	_run_ring(caster, caster.global_position)

func _run_ring(caster, origin: Vector3):
	var elapsed := 0.0
	var tick_interval := 0.5
	var center = origin

	while elapsed < ring_lifetime:
		await caster.get_tree().create_timer(tick_interval).timeout
		if !is_instance_valid(caster):
			return
		elapsed += tick_interval

		if elapsed <= follow_duration:
			center = caster.global_position

		var progress = clamp(elapsed / expand_duration, 0.0, 1.0)
		var current_radius = final_radius * progress

		var thermal = AbilityBase.find_passive(caster)

		for car in caster.get_tree().get_nodes_in_group("cars"):
			if car == caster:
				continue
			if car.global_position.distance_to(center) <= current_radius:
				if car.has_node("Health"):
					car.get_node("Health").take_damage(int(damage_per_second * tick_interval), caster)
				if car.has_node("StatusEffects"):
					car.get_node("StatusEffects").apply_status("slow", tick_interval * 1.5, slow_amount)
				if thermal and thermal.has_method("mark_vulnerable"):
					thermal.mark_vulnerable(car)
