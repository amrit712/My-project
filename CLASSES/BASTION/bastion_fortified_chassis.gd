extends PassiveBase
class_name BastionFortifiedChassis

# Passive - Fortified Chassis
# 15% less collision damage taken; enemy abilities cannot forcibly flip
# Bastion (it can still roll from its own momentum/physics); rear hits deal
# +10% more damage as a small tradeoff for its frontal tankiness.
#
# Integration note: this exposes modify_incoming_damage() for your
# CollisionManager/Health to call rather than doing it automatically,
# since damage there flows through Health.take_damage() which this node
# has no direct line into. In CollisionManager.process_collision(), before
# calling victim.health.take_damage(damage, hunter), do something like:
#
#   var passive = AbilityBase.find_passive(victim)
#   if passive is BastionFortifiedChassis:
#       damage = passive.modify_incoming_damage(damage, hit_from_rear)

@export var collision_damage_reduction: float = 0.15
@export var rear_hit_damage_bonus: float = 0.10

func on_process(_delta: float, caster: Node, _power_scale: float = 1.0):
	if caster.has_node("StatusEffects"):
		# Refreshed every frame so any ability that wants to forcibly flip
		# a car can check for "flip_immune" first and skip Bastion.
		caster.get_node("StatusEffects").apply_status("flip_immune", 0.2, 1.0)

func modify_incoming_damage(base_damage: int, hit_from_rear: bool, power_scale: float = 1.0) -> int:
	var modified = base_damage * (1.0 - collision_damage_reduction * power_scale)
	if hit_from_rear:
		modified *= (1.0 + rear_hit_damage_bonus)
	return int(round(modified))
