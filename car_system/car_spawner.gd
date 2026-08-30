extends Node
class_name CarSpawner

const CAR_BASE_SCENE: PackedScene = preload("res://car.tscn")

static func spawn_car(
	parent: Node,
	class_id: String,
	subclass_id: String,
	spawn_transform: Transform3D,
	is_player: bool,
	team_id: int = 0
):
	var class_data = CarRegistry.get_class_data(class_id)
	var subclass_data = CarRegistry.get_subclass_data(class_id, subclass_id)
	if class_data == null or subclass_data == null:
		push_error(
			"CarSpawner: could not find class '%s' / subclass '%s'"
			% [class_id, subclass_id]
		)
		return null

	var car = CAR_BASE_SCENE.instantiate()
	car.global_transform = spawn_transform
	car.is_player = is_player
	car.team_id = team_id
	car.car_class_name = class_id
	parent.add_child(car)

	# Apply class + subclass stats.
	car.mass = class_data.base_mass * subclass_data.mass_multiplier
	car.max_torque = class_data.base_max_torque * subclass_data.torque_multiplier
	car.max_rpm = class_data.base_max_rpm
	car.max_steering = class_data.base_max_steering * subclass_data.steering_multiplier

	# Add the subclass visual.
	if subclass_data.body_scene != null:
		var body_instance = subclass_data.body_scene.instantiate()
		var mount = car.get_node_or_null("BodyMeshSlot")
		if mount:
			mount.add_child(body_instance)
			ChassisCenterer.center_body(body_instance, subclass_data)
			body_instance.rotation_degrees = subclass_data.body_rotation_correction
			body_instance.scale = Vector3.ONE
			print("F1 instance scale: ", body_instance.scale)
			print("F1 instance global scale: ", body_instance.global_transform.basis.get_scale())
			for child in body_instance.get_children():
				if child is Node3D:
					print(
						"F1 child: ",
						child.name,
						" | scale: ",
						child.scale,
						" | global scale: ",
						child.global_transform.basis.get_scale()
					)

			# Reparent the body's designer wheel meshes onto the chassis's
			# physics wheel nodes (VehicleWheel3D) so suspension, steering,
			# and rolling rotation all drive them automatically. Must happen
			# AFTER the body is added under the mount and its own transform
			# is reset above, so the wheel meshes' global positions are
			# already correct before WheelAttacher reads them.
			WheelAttacher.attach_wheel_meshes(car, body_instance, subclass_data)

			# Must run AFTER WheelAttacher - by now the wheel meshes have
			# already been moved out of body_instance, so the generated
			# collision shape correctly covers only the car's body, not
			# the wheels (which have their own separate collision).
			CollisionShapeGenerator.fit_collision_to_body(car, body_instance)
		else:
			push_error("CarSpawner: BodyMeshSlot missing from car.tscn")

	# Add class abilities.
	_attach_ability(car, "Passive", class_data.passive_script)
	_attach_ability(car, "Ability1", class_data.ability1_script)
	_attach_ability(car, "Ability2", class_data.ability2_script)
	_attach_ability(car, "Ultimate", class_data.ultimate_script)

	# Bot cars need a CarAI node to actually drive - player cars read
	# keyboard input instead, so they don't need one.
	if not is_player:
		var ai := CarAI.new()
		ai.name = "CarAI"
		car.add_child(ai)

	return car

static func _attach_ability(
	car: Node,
	node_name: String,
	script: Script
) -> void:
	if script == null:
		return
	# IMPORTANT: script.new() (not Node.new() + set_script()) - the latter
	# does NOT call the script's _init(), which is where every ability sets
	# its real slot/cooldown/mana_cost. Using Node.new()+set_script() left
	# every spawned ability silently running with AbilityBase's raw
	# defaults (cooldown 0, mana_cost 0, slot ABILITY_1) instead of its
	# actual configured values.
	var node = script.new()
	node.name = node_name
	car.add_child(node)
