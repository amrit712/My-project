extends Node


const ARENA_SCENE: PackedScene = preload("res://ARENA/Arena2.tscn")

func _ready():

	print("=== GAME STARTED ===")


	# ========================================================
	# ARENA
	# ========================================================

	var arena := ARENA_SCENE.instantiate()

	add_child(arena)

	print(
		"Arena loaded ",
		arena.name
	)





	# ========================================================
	# PLAYER
	# ========================================================

	var spawn_transform := Transform3D.IDENTITY

	spawn_transform.origin = Vector3(
		0,
		2,
		0
	)


	print(
		"Calling CarSpawner for player..."
	)


	var car = CarSpawner.spawn_car(
		get_tree().current_scene,
		"NITRO",
		"Chiron",
		spawn_transform,
		true,
		0
	)


	if car == null:

		print(
			"!!! SPAWN FAILED: car is NULL !!!"
		)

	else:

		print(
			"!!! CAR SPAWNED: ",
			car.name,
			" / ",
			car.get_class()
		)

		print(
			"CAR POSITION: ",
			car.global_position
		)


	# ========================================================
	# BOT
	# ========================================================

	var bot_spawn_transform := (
		Transform3D.IDENTITY
	)

	bot_spawn_transform.origin = Vector3(
		10,
		2,
		10
	)


	print(
		"Calling CarSpawner for bot..."
	)


	var bot_car = CarSpawner.spawn_car(
		get_tree().current_scene,
		"NITRO",
		"Chiron",
		bot_spawn_transform,
		false,
		1
	)


	if bot_car == null:

		print(
			"!!! BOT SPAWN FAILED: bot_car is NULL !!!"
		)

	else:

		print(
			"!!! BOT CAR SPAWNED: ",
			bot_car.name,
			" / ",
			bot_car.get_class()
		)

		print(
			"BOT CAR POSITION: ",
			bot_car.global_position
		)
