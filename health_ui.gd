extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_number: Label = $HealthNumber

var car: VehicleBody3D = null
var health_component: Node = null

func _ready():
	_try_find_car()

func _process(_delta):
	if car == null or health_component == null:
		# Car hasn't been spawned yet (CarSpawner runs after this UI's
		# _ready(), since Godot calls _ready() bottom-up) - keep retrying
		# each frame until it exists, instead of giving up permanently.
		_try_find_car()
		return
	update_health()

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

	health_component = car.get_node_or_null("Health")
	if health_component == null:
		push_error("HealthUI: Car has no Health node.")
		return

	health_bar.min_value = 0
	health_bar.max_value = health_component.max_health
	update_health()

func update_health():
	var current_health = health_component.health
	var max_health = health_component.max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_number.text = str(current_health)
