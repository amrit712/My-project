extends AbilityBase
class_name BastionImmovableObject

# Ultimate - Immovable Object
# For 10s: 40% damage reduction, fixed medium top speed, reduced turning,
# immune to knockback from normal abilities. Front rams against Bastion
# reflect 75% of the collision damage back onto the attacker.

@export var duration: float = 10.0
@export var damage_reduction: float = 0.40
@export var reflect_percent: float = 0.75
@export var fixed_top_speed: float = 15.0
@export var turning_multiplier: float = 0.5

func _init():
	slot = Slot.ULTIMATE
	cooldown = 60.0
	mana_cost = 100.0

var is_active: bool = false
var _timer: float = 0.0

func activate(caster):
	is_active = true
	_timer = duration
	if caster.has_node("StatusEffects"):
		var se = caster.get_node("StatusEffects")
		se.apply_status("immovable", duration, 1.0)
		se.apply_status("no_knockback", duration, 1.0)
		se.apply_status("speed_cap", duration, fixed_top_speed)
		se.apply_status("turning_reduced", duration, turning_multiplier)
	print(caster.name, " becomes an Immovable Object")

func _process(delta):
	super._process(delta)
	if is_active:
		_timer -= delta
		if _timer <= 0.0:
			is_active = false
			print(get_parent().name, "'s Immovable Object ends")

# Call from wherever incoming damage is applied to Bastion.
func modify_incoming_damage(base_damage: int) -> int:
	if is_active:
		return int(round(base_damage * (1.0 - damage_reduction)))
	return base_damage

# Call from CollisionManager: when an enemy rams Bastion from the front
# while this is active, this returns how much damage to reflect back onto
# the attacker (call it in addition to, not instead of, normal resolution).
func get_reflect_damage(incoming_damage: int) -> int:
	if is_active:
		return int(round(incoming_damage * reflect_percent))
	return 0
