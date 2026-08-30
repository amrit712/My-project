extends AbilityBase
class_name EngineerEnergyDrain

# Ability 2 - Energy Drain
# Fires a slow, single-target energy disc. On hit: target loses 35% of
# their current mana, Engineer recovers 20% of the drained amount, target
# is slowed 10% for 3s.

@export var disc_speed: float = 14.0
@export var disc_lifetime: float = 3.0
@export var drain_percent: float = 0.35
@export var return_percent: float = 0.20
@export var slow_amount: float = 0.10
@export var slow_duration: float = 3.0

func _init():
	slot = Slot.ABILITY_2
	cooldown = 12.0
	mana_cost = 25

func activate(caster):
	if caster.get("offensive_abilities_locked") == true:
		print(caster.name, " can't use Energy Drain while Repair Link is active")
		return

	var velocity = -caster.global_transform.basis.z * disc_speed
	var from_transform = caster.global_transform
	from_transform.origin += -caster.global_transform.basis.z * 2.0

	ArenaProjectile.spawn(
		caster.get_tree(), from_transform, 0.4, velocity,
		disc_lifetime, caster,
		func(target): _on_disc_hit(caster, target),
		true
	)
	print(caster.name, " fires Energy Drain")

func _on_disc_hit(caster, target):
	if target.has_node("Mana"):
		var target_mana = target.get_node("Mana")
		var drained = target_mana.mana * drain_percent
		target_mana.mana = max(0.0, target_mana.mana - drained)
		target_mana.mana_changed.emit(target_mana.mana, target_mana.max_mana)
		if caster.has_node("Mana"):
			caster.get_node("Mana").add_mana(drained * return_percent)

	if target.has_node("StatusEffects"):
		target.get_node("StatusEffects").apply_status("slow", slow_duration, slow_amount)

	print(caster.name, " drains ", target.name, "'s energy")
