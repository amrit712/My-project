class_name AbilityBase
extends Node

# Base class every activatable ability (Ability 1, Ability 2, Ultimate)
# extends. Handles mana cost, cooldown, and a couple of cross-class hooks
# (Nitro's charge-consume, All-Rounder's chain/apex refresh) so individual
# ability scripts only need to implement activate().
#
# IMPORTANT - Godot subclass rule: because `slot`, `cooldown`, and
# `mana_cost` are declared here, subclasses must NEVER redeclare them with
# @export or `var` again (that's a parse error - "member already exists in
# parent class"). Subclasses set their own defaults inside `_init()`
# instead, e.g.:
#
#   func _init():
#       slot = Slot.ABILITY_1
#       cooldown = 16.0

enum Slot { ABILITY_1, ABILITY_2, ULTIMATE }

@export var mana_cost: float = 0.0
@export var cooldown: float = 0.0
@export var slot: Slot = Slot.ABILITY_1

var _cooldown_timer: float = 0.0
# One-shot cooldown multiplier consumed on the NEXT try_activate() call.
# Set this externally (e.g. Nitro's Momentum Engine, All-Rounder's Fluid
# Driver) before the player presses the button, and it resets to 1.0 after use.
var pending_cooldown_multiplier: float = 1.0

func _process(delta):
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func get_cooldown_remaining() -> float:
	return max(_cooldown_timer, 0.0)

func can_activate(caster) -> bool:
	# A destroyed/wrecked car cannot use abilities - checked here once so
	# every ability in the roster is protected, not just individually.
	if "destroyed" in caster and caster.destroyed:
		return false
	if _cooldown_timer > 0.0:
		return false
	if mana_cost > 0.0 and caster.has_node("Mana"):
		if not caster.get_node("Mana").has_enough(mana_cost):
			return false
	return true

func try_activate(caster) -> bool:
	if !can_activate(caster):
		return false

	if mana_cost > 0.0 and caster.has_node("Mana"):
		caster.get_node("Mana").spend(mana_cost)

	var applied_cooldown = cooldown * pending_cooldown_multiplier
	# All-Rounder's Apex Mode: +20% ability recharge for everyone while it's up
	# (only matters if THIS caster happens to have it and it's active).
	if caster.has_node("StatusEffects") and caster.get_node("StatusEffects").has_status("apex_mode"):
		applied_cooldown *= 0.80

	_cooldown_timer = applied_cooldown
	pending_cooldown_multiplier = 1.0

	activate(caster)

	# If this caster has All-Rounder's Apex Mode ultimate, let it know an
	# ability just fired so it can refresh 25% of the others' cooldowns.
	# Harmless no-op for every other class (has_method just returns false).
	var maybe_apex = find_ability(caster, Slot.ULTIMATE)
	if maybe_apex and maybe_apex != self and maybe_apex.has_method("on_any_ability_used"):
		maybe_apex.on_any_ability_used(caster, slot)

	return true

func activate(_caster):
	pass  # override in each ability subclass

# ---- Shared helpers, usable by any ability script ----

static func get_nearby_cars(caster: Node, radius: float = -1.0, include_self: bool = false) -> Array:
	var result: Array = []
	var cars = caster.get_tree().get_nodes_in_group("cars")
	for car in cars:
		if car == caster and !include_self:
			continue
		if radius > 0.0 and car.global_position.distance_to(caster.global_position) > radius:
			continue
		result.append(car)
	return result

static func find_ability(car: Node, target_slot: int) -> AbilityBase:
	for child in car.get_children():
		if child is AbilityBase and child.slot == target_slot:
			return child
	return null

static func find_passive(car: Node) -> PassiveBase:
	for child in car.get_children():
		if child is PassiveBase:
			return child
	return null
