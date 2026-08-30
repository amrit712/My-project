extends AbilityBase
class_name EngineerRepairLink

# Ability 1 - Repair Link
# Locks onto the nearest ally within 18m. For 3s, that ally regenerates
# 30% of their missing HP (applied smoothly over the duration). Engineer
# drives normally but cannot use offensive abilities while linked. Breaking
# range ends the link early.
#
# Requires each car to expose `team_id` (int) for ally detection - add
# `@export var team_id: int = 0` to CarController if it isn't there yet.
# Also sets `offensive_abilities_locked` on the caster - your Ability 2
# (Energy Drain) should check that flag before firing.

@export var link_range: float = 18.0
@export var link_duration: float = 3.0
@export var heal_percent_of_missing: float = 0.30

func _init():
	slot = Slot.ABILITY_1
	cooldown = 20.0
	mana_cost = 20

var is_linked: bool = false
var _linked_ally: Node = null
var _timer: float = 0.0

func activate(caster):
	var ally = _find_nearest_ally(caster)
	if ally == null:
		print(caster.name, " has no ally in range for Repair Link")
		return
	is_linked = true
	_linked_ally = ally
	_timer = link_duration
	caster.set("offensive_abilities_locked", true)
	print(caster.name, " links to ", ally.name)

func _find_nearest_ally(caster) -> Node:
	var closest = null
	var closest_dist = link_range
	for car in caster.get_tree().get_nodes_in_group("cars"):
		if car == caster or not car.can_take_collision_damage():
			continue
		if "team_id" in car and "team_id" in caster and car.team_id != caster.team_id:
			continue
		var dist = car.global_position.distance_to(caster.global_position)
		if dist <= closest_dist:
			closest = car
			closest_dist = dist
	return closest

func _process(delta):
	super._process(delta)
	if !is_linked:
		return
	var caster = get_parent()

	if _linked_ally == null or !is_instance_valid(_linked_ally):
		_break_link(caster)
		return
	if caster.global_position.distance_to(_linked_ally.global_position) > link_range:
		_break_link(caster)
		return

	_timer -= delta
	if _linked_ally.has_node("Health"):
		var h = _linked_ally.get_node("Health")
		var missing = h.max_health - h.health
		if missing > 0:
			h.heal(int(ceil(missing * heal_percent_of_missing * (delta / link_duration))))

	if _timer <= 0.0:
		_break_link(caster)

func _break_link(caster):
	is_linked = false
	_linked_ally = null
	caster.set("offensive_abilities_locked", false)
	print(caster.name, "'s Repair Link ends")
