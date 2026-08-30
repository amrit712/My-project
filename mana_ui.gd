extends Control

@onready var mana_bar: ProgressBar = $ManaBar

var car: VehicleBody3D = null
var mana_component: Node = null

func _ready():
	_try_find_car()

func _process(_delta):
	if car == null or mana_component == null:
		# Car hasn't been spawned yet (CarSpawner runs after this UI's
		# _ready(), since Godot calls _ready() bottom-up) - keep retrying
		# each frame until it exists, instead of giving up permanently.
		_try_find_car()
		return
	update_mana()

func _try_find_car():
	car = null
	# Filter for the PLAYER's car specifically, not just any car - once AI
	# opponents exist in the same "cars" group, get_first_node_in_group()
	# would grab whichever one happens to be first instead of the player.
	for c in get_tree().get_nodes_in_group("cars"):
		if "is_player" in c and c.is_player:
			car = c
			break

	if car == null:
		return  # not spawned yet - stay quiet, we'll just try again next frame

	mana_component = car.get_node_or_null("Mana")
	if mana_component == null:
		push_error("ManaUI: Car has no Mana node.")
		return

	update_mana()

func update_mana():
	var current_mana = mana_component.mana
	var max_mana = mana_component.max_mana
	mana_bar.min_value = 0
	mana_bar.max_value = max_mana
	mana_bar.value = current_mana
