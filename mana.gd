extends Node
signal mana_changed(current: float, max: float)

@export var max_mana: float = 100.0
@export var regen_rate: float = 0.4            # normal passive regen, mana/sec
@export var overdrive_regen_rate: float = 1.0  # overdrive regen, mana/sec
@export var overdrive_health_threshold: float = 20.0  # % of max health

var mana: float = max_mana
@onready var health: Node = get_parent().get_node_or_null("Health")

func _process(delta):
	if mana >= max_mana:
		return

	var rate = regen_rate
	if _is_overdrive_active():
		rate = max(rate, overdrive_regen_rate)
		# ^ use whichever is higher, in case normal regen is already faster

	mana = min(max_mana, mana + rate * delta)
	mana_changed.emit(mana, max_mana)

func _is_overdrive_active() -> bool:
	if !health:
		return false
	var health_percent = (float(health.health) / float(health.max_health)) * 100.0
	return health_percent <= overdrive_health_threshold and !health.dead

func has_enough(cost: float) -> bool:
	return mana >= cost

func spend(cost: float) -> bool:
	if !has_enough(cost):
		return false
	mana -= cost
	mana_changed.emit(mana, max_mana)
	return true

func add_mana(amount: float):
	mana = min(max_mana, mana + amount)
	mana_changed.emit(mana, max_mana)
