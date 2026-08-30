class_name PassiveBase
extends Node

# Base class every class's Passive extends. Unlike AbilityBase, passives
# have no activation/cooldown - they just run continuously.
#
# `power_scale` exists specifically for Engineer's Inheritance Protocol:
# it finds another car's PassiveBase child and calls on_process() on it
# directly, passing the Engineer as `caster` and 0.7 as power_scale. Each
# concrete passive should multiply its magnitude-based effects by
# power_scale so "copied at 70% power" works automatically without
# Inheritance Protocol needing to know the details of each passive.

func _physics_process(delta):
	var caster = get_parent()
	if caster:
		on_process(delta, caster, 1.0)

func on_process(_delta: float, _caster: Node, _power_scale: float = 1.0):
	pass  # override in subclass
