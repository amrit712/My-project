extends Node


func _ready() -> void:
	print("MAIN MENU")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("Starting server...")

		var error := await NetworkManager.host_game()

		if error != OK:
			print("Server error: ", error)
		else:
			print("HOSTING")


	if event.is_action_pressed("ui_cancel"):
		print("Joining Noray host...")

		var error := await NetworkManager.join_game(
			"K-MBl1Qa0KZJ46eVbv9VA"
		)

		if error != OK:
			print("Client error: ", error)
		else:
			print("JOIN REQUEST SENT")
