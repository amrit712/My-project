extends AbilityBase
class_name BastionReinforcedCharge

# Ability 2 - Reinforced Charge
# Locks steering and shoves Bastion forward 8m at high speed. On collision:
# damage + knockback that scales with Bastion's current speed, and Bastion
# keeps moving through the hit rather than stopping.
#
# Integration note: your CarController needs to check a flag (here:
# `steering_locked`) and skip normal steering input while it's true.

@export var charge_distance: float = 8.0
@export var charge_speed: float = 22.0
@export var base_damage: int = 20
@export var knockback_base_speed: float = 8.0    # m/s of knockback at low charge speed
@export var knockback_speed_scale: float = 0.6    # extra knockback per m/s of charge speed

func _init():
	slot = Slot.ABILITY_2
	cooldown = 12.0
	mana_cost = 35

var _charging: bool = false
var _traveled: float = 0.0
var _already_hit: Dictionary = {}  # instance id -> true, so one victim isn't hit every frame of the charge

func activate(caster):
	_charging = true
	_traveled = 0.0
	_already_hit.clear()
	caster.set("steering_locked", true)
	caster.linear_velocity = -caster.global_transform.basis.z * charge_speed
	print(caster.name, " begins Reinforced Charge")

func _physics_process(delta):
	if !_charging:
		return
	var caster = get_parent()
	_traveled += charge_speed * delta
	caster.linear_velocity = -caster.global_transform.basis.z * charge_speed

	for body in caster.get_colliding_bodies():
		if body.is_in_group("cars") and body != caster and not _already_hit.has(body.get_instance_id()):
			_already_hit[body.get_instance_id()] = true
			_on_charge_hit(caster, body)

	if _traveled >= charge_distance:
		_end_charge(caster)

func _end_charge(caster):
	_charging = false
	caster.set("steering_locked", false)
	print(caster.name, "'s Reinforced Charge ends")

func _on_charge_hit(caster, victim):
	var speed = caster.linear_velocity.length()
	var knockback_speed = knockback_base_speed + speed * knockback_speed_scale
	var direction = (victim.global_position - caster.global_position).normalized()
	# Mass-normalized impulse so knockback_speed is the actual m/s of Δv
	# the victim gets, regardless of their mass - same pattern as Shockwave.
	victim.apply_central_impulse(direction * knockback_speed * victim.mass)

	if victim.has_node("Health"):
		victim.get_node("Health").take_damage(base_damage, caster)

	print(caster.name, " rams ", victim.name, " with Reinforced Charge")
