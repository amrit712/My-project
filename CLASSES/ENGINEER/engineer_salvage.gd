extends PassiveBase
class_name EngineerSalvage

# Passive - Salvage
# Driving near a wreck restores 8% max HP and 10% max mana ("ultimate
# charge"). Each wreck can only be salvaged once, so Engineer can't just
# park on top of one car forever.

@export var salvage_radius: float = 3.0
@export var heal_percent: float = 0.08
@export var mana_restore_percent: float = 0.10

var _salvaged_wrecks: Dictionary = {}  # wreck instance id -> true

func on_process(_delta: float, caster: Node, power_scale: float = 1.0):
	for car in caster.get_tree().get_nodes_in_group("cars"):
		if car == caster:
			continue
		if not ("state" in car) or car.state != car.CarState.WRECK:
			continue

		var id = car.get_instance_id()
		if _salvaged_wrecks.has(id):
			continue

		if car.global_position.distance_to(caster.global_position) <= salvage_radius:
			_salvage(caster, car, power_scale)
			_salvaged_wrecks[id] = true

func _salvage(caster, wreck, power_scale: float):
	if caster.has_node("Health"):
		var h = caster.get_node("Health")
		h.heal(int(h.max_health * heal_percent * power_scale))
	if caster.has_node("Mana"):
		var m = caster.get_node("Mana")
		m.add_mana(m.max_mana * mana_restore_percent * power_scale)
	print(caster.name, " salvages ", wreck.name)
