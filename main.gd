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
			print("Noray connected: ", Noray.is_connected_to_host())
			print("Noray OID: ", Noray.oid)
			print("Noray local port: ", Noray.local_port)


	if event.is_action_pressed("ui_cancel"):
		print("Joining Noray host...")

		var error := await NetworkManager.join_game(
			"11M1JXqrh4bH3bm5slL5a"
		)

		if error != OK:
			print("Client error: ", error)
		else:
			print("JOIN REQUEST SENT")
