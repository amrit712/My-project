extends Node
signal died(killer: Node)

@export var max_health := 100
@export var mana_per_damage_dealt: float = 0.5   # attacker gains this * damage
@export var mana_per_damage_taken: float = 0.3   # victim gains this * damage

var health := max_health
var dead := false
var last_attacker: Node = null
var damage_contributions := {}

func take_damage(amount: int, attacker: Node = null):
	if dead:
		return
	if attacker:
		last_attacker = attacker
		var id = attacker.get_instance_id()
		damage_contributions[id] = damage_contributions.get(id, 0) + amount

	health -= amount
	print(name, " HP:", health)

	# Mana gain: victim gets some for getting hit
	_grant_mana(get_parent(), amount * mana_per_damage_taken)
	# Mana gain: attacker gets some for landing the hit
	if attacker and is_instance_valid(attacker):
		_grant_mana(attacker, amount * mana_per_damage_dealt)

	if health <= 0:
		health = 0
		dead = true
		died.emit(last_attacker)

func heal(amount: int):
	if dead:
		return
	health = min(max_health, health + amount)

func _grant_mana(car: Node, amount: float):
	if car and is_instance_valid(car) and car.has_node("Mana"):
		car.get_node("Mana").add_mana(amount)
