extends AbilityBase
class_name AllRounderTrackerDart

# Ability 1 - Tracker Dart
# Fires a single-target dart. On hit: reveals the target for 5s (outline
# status), and the NEXT collision All-Rounder lands on them deals +15%
# bonus damage (consumed on use).

@export var dart_speed: float = 18.0
@export var dart_lifetime: float = 2.5
@export var outline_duration: float = 5.0
@export var bonus_damage_percent: float = 0.15

func _init():
	slot = Slot.ABILITY_1
	cooldown = 11.0
	mana_cost = 15

func activate(caster):
	var fluid_driver = AbilityBase.find_passive(caster)
	if fluid_driver and fluid_driver.has_method("on_ability_used"):
		fluid_driver.on_ability_used(caster, slot)

	var velocity = -caster.global_transform.basis.z * dart_speed
	var from_transform = caster.global_transform
	from_transform.origin += -caster.global_transform.basis.z * 2.0

	ArenaProjectile.spawn(
		caster.get_tree(), from_transform, 0.3, velocity,
		dart_lifetime, caster,
		func(target): _on_dart_hit(caster, target),
		true
	)
	print(caster.name, " fires Tracker Dart")

func _on_dart_hit(caster, target):
	if target.has_node("StatusEffects"):
		var se = target.get_node("StatusEffects")
		se.apply_status("revealed", outline_duration, 1.0)
		se.apply_status("marked_by_" + str(caster.get_instance_id()), outline_duration, bonus_damage_percent)
	print(caster.name, " marks ", target.name)

# Call from CollisionManager when resolving a hit: if the attacker
# previously marked the victim, this returns the bonus % (and consumes
# the mark) - otherwise returns 0.0.
static func get_and_consume_mark_bonus(attacker: Node, victim: Node) -> float:
	if not victim.has_node("StatusEffects"):
		return 0.0
	var key = "marked_by_" + str(attacker.get_instance_id())
	var se = victim.get_node("StatusEffects")
	if se.has_status(key):
		var bonus = se.get_magnitude(key)
		se.clear_status(key)
		return bonus
	return 0.0
