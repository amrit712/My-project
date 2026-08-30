extends Node

# Pairs that were touching last physics frame
var active_pairs := {}
const PAIR_COOLDOWN := 1.0
var pair_cooldowns := {}

# Tune these to taste
const IMPACT_THRESHOLDS := [4.0, 8.0, 12.0, 16.0]
const VICTIM_DAMAGE_TIERS := [10, 25, 45, 70]
const HUNTER_DAMAGE_SCALE := 0.40  # hunter takes only 40% of the victim's damage

func _physics_process(delta):
	var current_pairs := {}
	var cars = get_tree().get_nodes_in_group("cars")

	for key in pair_cooldowns.keys():
		pair_cooldowns[key] -= delta
		if pair_cooldowns[key] <= 0:
			pair_cooldowns.erase(key)

	for car in cars:
		if !car.can_take_collision_damage():
			continue
		for body in car.get_colliding_bodies():
			if !(body is VehicleBody3D):
				continue
			if !body.is_in_group("cars"):
				continue
			if !body.can_take_collision_damage():
				continue

			var id1 = car.get_instance_id()
			var id2 = body.get_instance_id()
			var key = str(min(id1, id2), "_", max(id1, id2))

			current_pairs[key] = true

			if active_pairs.has(key):
				continue
			if pair_cooldowns.has(key):
				continue

			pair_cooldowns[key] = PAIR_COOLDOWN
			process_collision(car, body)

	active_pairs = current_pairs


func process_collision(car_a: VehicleBody3D, car_b: VehicleBody3D):
	var direction = (car_b.global_position - car_a.global_position).normalized()
	var a_towards_b = car_a.linear_velocity.dot(direction)
	var b_towards_a = car_b.linear_velocity.dot(-direction)

	# car_a becomes the HUNTER (drove into the other), car_b the VICTIM (got hit)
	var hunter = car_a
	var victim = car_b
	if b_towards_a > a_towards_b:
		hunter = car_b
		victim = car_a

	var impact_speed = (
		hunter.previous_velocity - victim.previous_velocity
	).length()

	var victim_damage = compute_damage(impact_speed)
	var hunter_damage = int(victim_damage * HUNTER_DAMAGE_SCALE)

	if victim_damage <= 0:
		return

	victim.health.take_damage(victim_damage, hunter)
	if victim.is_player and victim.has_node("Camera3D/CameraShake"):
		victim.get_node("Camera3D/CameraShake").add_trauma(clamp(victim_damage / 100.0, 0.0, 1.0))
	if hunter_damage > 0:
		hunter.health.take_damage(hunter_damage, victim)

	print(
		hunter.name, " rammed ", victim.name,
		" | Impact:", snapped(impact_speed, 0.1),
		" | victim dmg:", victim_damage,
		" | hunter dmg:", hunter_damage
	)


func compute_damage(impact_speed: float) -> int:
	for i in range(IMPACT_THRESHOLDS.size() - 1, -1, -1):
		if impact_speed > IMPACT_THRESHOLDS[i]:
			return VICTIM_DAMAGE_TIERS[i]
	return 0
