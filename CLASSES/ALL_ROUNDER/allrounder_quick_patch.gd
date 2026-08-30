extends AbilityBase
class_name AllRounderQuickPatch

# Ability 2 - Quick Patch
# Instant heal for 18% max HP + cleanses Slow, Burn, and Concussed.
# Can only be used while missing at least 5% HP, so it can't be spammed
# purely as a free cleanse at full health.
# +5% extra healing while Apex Mode (the ultimate) is active.

@export var heal_percent: float = 0.18
@export var min_missing_percent_to_use: float = 1.00
@export var apex_mode_bonus_heal: float = 0.05

func _init():
	slot = Slot.ABILITY_2
	cooldown = 20.0
	mana_cost = 25

func can_activate(caster) -> bool:
	if !super.can_activate(caster):
		return false
	if caster.has_node("Health"):
		var h = caster.get_node("Health")
		var missing_percent = 1.0 - (float(h.health) / float(h.max_health))
		if missing_percent < min_missing_percent_to_use:
			return false
	return true

func activate(caster):
	var fluid_driver = AbilityBase.find_passive(caster)
	if fluid_driver and fluid_driver.has_method("on_ability_used"):
		fluid_driver.on_ability_used(caster, slot)

	if caster.has_node("Health"):
		var h = caster.get_node("Health")
		var heal_pct = heal_percent
		if caster.has_node("StatusEffects") and caster.get_node("StatusEffects").has_status("apex_mode"):
			heal_pct += apex_mode_bonus_heal
		h.heal(int(h.max_health * heal_pct))

	if caster.has_node("StatusEffects"):
		var se = caster.get_node("StatusEffects")
		se.clear_status("slow")
		se.clear_status("burn")
		se.clear_status("concussed")

	print(caster.name, " uses Quick Patch")
