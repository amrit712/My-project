extends PassiveBase
class_name HavocThermalAmplifier

# Passive - Thermal Amplifier
# Purely reactive - it doesn't run anything on its own each frame. Havoc's
# other abilities (Napalm Trail, Scorched Earth) call mark_vulnerable()
# whenever they damage a target, applying +12% damage taken from ALL
# sources for 4s (this is what enables the "Havoc burns -> Bastion rams ->
# Nitro finishes" combo from the design doc).

@export var vulnerable_bonus: float = 0.12
@export var vulnerable_linger: float = 4.0

func on_process(_delta: float, _caster: Node, _power_scale: float = 1.0):
	pass

func mark_vulnerable(target: Node, power_scale: float = 1.0):
	if target.has_node("StatusEffects"):
		target.get_node("StatusEffects").apply_status(
			"vulnerable", vulnerable_linger, vulnerable_bonus * power_scale, true
		)
