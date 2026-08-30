extends AbilityBase
class_name EngineerInheritanceProtocol

# Ultimate - Inheritance Protocol
# Targets a wreck within 20m. For 15s, Engineer copies that class's Passive
# at 70% effectiveness, and immediately gets one free use of that class's
# Ability 1 (bypasses its mana cost and cooldown entirely). Cannot target
# another Engineer's wreck.
#
# Requires each car to expose a `car_class_name` String (e.g. "NITRO",
# "BASTION", ...) for the Engineer-restriction check - add
# `@export var car_class_name: String = ""` to CarController if missing.

@export var range_to_wreck: float = 20.0
@export var duration: float = 15.0
@export var power_scale: float = 0.70

func _init():
	slot = Slot.ULTIMATE
	cooldown = 75.0
	mana_cost = 100.0

var _active_passive: PassiveBase = null
var _timer: float = 0.0

func activate(caster):
	var wreck = _find_nearest_wreck(caster)
	if wreck == null:
		print(caster.name, " found no wreck in range to copy")
		return

	var source_passive = AbilityBase.find_passive(wreck)
	var source_ability1 = AbilityBase.find_ability(wreck, AbilityBase.Slot.ABILITY_1)

	if source_passive == null:
		print(wreck.name, " has no passive to copy")
		return

	_active_passive = source_passive
	_timer = duration

	if source_ability1 != null:
		# Direct activate() call - deliberately skips the copied ability's
		# own mana cost and cooldown, since this is a "free use."
		source_ability1.activate(caster)
		print(caster.name, " gains a free use of ", wreck.name, "'s Ability 1")

	print(caster.name, " inherits ", wreck.name, "'s passive at ",
		int(power_scale * 100), "% power for ", duration, "s")

func _find_nearest_wreck(caster) -> Node:
	var closest = null
	var closest_dist = range_to_wreck
	for car in caster.get_tree().get_nodes_in_group("cars"):
		if car == caster or not ("state" in car) or car.state != car.CarState.WRECK:
			continue
		if "car_class_name" in car and car.car_class_name == "ENGINEER":
			continue  # cannot copy another Engineer
		var dist = car.global_position.distance_to(caster.global_position)
		if dist <= closest_dist:
			closest = car
			closest_dist = dist
	return closest

func _process(delta):
	super._process(delta)
	if _active_passive != null and _timer > 0.0:
		_timer -= delta
		_active_passive.on_process(delta, get_parent(), power_scale)
		if _timer <= 0.0:
			_active_passive = null
			print(get_parent().name, "'s inherited passive expires")
