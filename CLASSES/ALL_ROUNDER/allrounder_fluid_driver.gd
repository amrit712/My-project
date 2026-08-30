extends PassiveBase
class_name AllRounderFluidDriver

# Passive - Fluid Driver
# Every ability use gives the NEXT ability in the chain (Ability1 ->
# Ability2 -> Ultimate -> Ability1 -> ...) -20% cooldown. Each All-Rounder
# ability's activate() calls on_ability_used() at the start of its own
# activate() to trigger this.

@export var chain_reduction: float = 0.20

func on_ability_used(caster: Node, used_slot: int):
	var next_slot = _next_in_chain(used_slot)
	var next_ability = AbilityBase.find_ability(caster, next_slot)
	if next_ability:
		next_ability.pending_cooldown_multiplier = 1.0 - chain_reduction

func _next_in_chain(slot: int) -> int:
	match slot:
		AbilityBase.Slot.ABILITY_1:
			return AbilityBase.Slot.ABILITY_2
		AbilityBase.Slot.ABILITY_2:
			return AbilityBase.Slot.ULTIMATE
		AbilityBase.Slot.ULTIMATE:
			return AbilityBase.Slot.ABILITY_1
	return AbilityBase.Slot.ABILITY_1

func on_process(_delta: float, _caster: Node, _power_scale: float = 1.0):
	pass
