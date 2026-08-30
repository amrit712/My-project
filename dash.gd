extends Node


@export_category("Dash")

@export var dash_acceleration: float = 20.0


@export_category("Mana")

@export var mana_cost_per_second: float = 25.0


@export_category("Input")

@export var dash_action: String = "dash"


var car: VehicleBody3D
var mana: Node

var dash_active: bool = false


func _ready() -> void:

	car = get_parent() as VehicleBody3D

	if car == null:

		push_error(
			"Dash must be a child of a VehicleBody3D."
		)

		return


	mana = car.get_node_or_null("Mana")

	if mana == null:

		push_error(
			"Dash could not find a Mana node on the car."
		)


func _physics_process(delta: float) -> void:

	if car == null or mana == null:
		return

	if not car.is_player:
		return
	# --------------------------------------------------------
	# TOGGLE DASH
	# --------------------------------------------------------

	if Input.is_action_just_pressed(dash_action):

		toggle_dash()


	# --------------------------------------------------------
	# MANA DRAIN
	# --------------------------------------------------------

	if dash_active:

		var mana_cost: float = (
			mana_cost_per_second * delta
		)


		# ----------------------------------------------------
		# ENOUGH MANA
		# ----------------------------------------------------

		if mana.has_enough(mana_cost):

			mana.spend(mana_cost)


		# ----------------------------------------------------
		# NOT ENOUGH MANA
		# ----------------------------------------------------

		else:

			# Spend whatever remains.
			if mana.mana > 0.0:

				mana.spend(mana.mana)


			stop_dash()


func toggle_dash() -> void:

	if dash_active:

		stop_dash()

	else:

		start_dash()


func start_dash() -> void:

	if dash_active:
		return


	# Don't start with zero Mana.

	if mana.mana <= 0.0:
		return


	car.sleeping = false


	# -1 means infinite duration.

	car.start_boost(
		dash_acceleration,
		-1.0
	)


	dash_active = true


	print(
		"DASH ON | ",
		car.name,
		" | acceleration = ",
		dash_acceleration
	)


func stop_dash() -> void:

	if not dash_active:
		return


	dash_active = false


	car.stop_boost()


	print(
		"DASH OFF | ",
		car.name
	)
