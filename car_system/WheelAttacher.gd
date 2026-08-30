class_name WheelAttacher
extends RefCounted


const WHEEL_NAME_MAP := {
	"back_left": "BACK-LEFT",
	"back_right": "BACK-RIGHT",
	"front_left": "FRONT-LEFT",
	"front_right": "FRONT-RIGHT",
}


static func attach_wheel_meshes(
	car: Node,
	body_instance: Node,
	subclass_data: CarSubclassData = null
):
	for visual_name in WHEEL_NAME_MAP.keys():
		var physics_name: String = WHEEL_NAME_MAP[visual_name]
		var visual_node: Node3D = body_instance.find_child(visual_name, true, false)
		var physics_node: Node3D = car.get_node_or_null(physics_name)

		if physics_node == null:
			push_warning("WheelAttacher: missing physics wheel: %s" % physics_name)
			continue

		if visual_node != null:
			_align_physics_wheel_to_visual(visual_node, physics_node)

		var offset: Vector3 = Vector3.ZERO
		if subclass_data != null:
			match visual_name:
				"back_left": offset = subclass_data.back_left_wheel_offset
				"back_right": offset = subclass_data.back_right_wheel_offset
				"front_left": offset = subclass_data.front_left_wheel_offset
				"front_right": offset = subclass_data.front_right_wheel_offset

		physics_node.global_position += offset

		# ==================================================================
		# STEP 3 — ACTUALLY ATTACH THE MESH TO THE PHYSICS WHEEL
		# ==================================================================
		# Everything above only moved physics_node to the right SPOT — the
		# mesh itself is still parented under body_instance and has never
		# moved. Reparent it now so it sits exactly at physics_node's
		# (now-correct) origin and inherits the node's suspension/steering/
		# rolling transform automatically every frame.
		if visual_node != null:
			# Capture the mesh's own local scale BEFORE we touch anything.
			# Some models (e.g. the F1 body) bake a corrective scale onto
			# the wheel node itself so it matches the chassis's unit scale.
			# Resetting the whole transform to identity below wipes that
			# out along with position/rotation - if we don't restore it,
			# the wheel renders at its raw, un-corrected native scale
			# (huge, floating, disconnected from the chassis).
			var original_scale: Vector3 = visual_node.scale

			var old_parent := visual_node.get_parent()
			if old_parent:
				old_parent.remove_child(visual_node)
			physics_node.add_child(visual_node)

			# Zero out position/rotation so the mesh sits exactly at
			# physics_node's origin, but restore the captured scale -
			# identity would otherwise silently drop any corrective scale
			# baked into the model.
			visual_node.transform = Transform3D.IDENTITY
			visual_node.scale = original_scale

			if subclass_data != null:
				visual_node.rotation_degrees = subclass_data.wheel_rotation_correction

		# Force VehicleBody3D to pick up this wheel's corrected transform.
		# Godot caches each wheel's suspension connection point at the
		# moment the VehicleWheel3D node enters the tree (see godot#63657)
		# and does not keep tracking its live transform after that. Since
		# our repositioning happens AFTER the car - and its default-
		# positioned wheels - already entered the tree via add_child(car)
		# in CarSpawner, the cached connection point is stale. Removing
		# and re-adding the wheel node forces a fresh ENTER_TREE
		# notification now that it's sitting in its final, correct spot.
		var wheel_parent := physics_node.get_parent()
		wheel_parent.remove_child(physics_node)
		wheel_parent.add_child(physics_node)


# ============================================================================
# AUTO DETECTION
# ============================================================================

static func _align_physics_wheel_to_visual(
	visual_node: Node3D,
	physics_node: Node3D
):
	var local_center: Vector3 = _compute_local_center(visual_node)
	var target_global_position: Vector3 = visual_node.to_global(local_center)

	# VehicleWheel3D's own origin is the SUSPENSION ATTACH POINT, not the
	# wheel's visual position - the wheel hangs `wheel_rest_length` meters
	# below the node's origin along its local -Y (see docs on
	# wheel_rest_length). Since the wheel mesh will be parented at local
	# zero under this node, we have to push the node's origin UP by
	# rest_length so that the mesh (and the simulated wheel) end up at the
	# visual mesh's actual center, not above it.
	var rest_length: float = 0.0
	if physics_node is VehicleWheel3D:
		rest_length = physics_node.wheel_rest_length

	var up_dir: Vector3 = physics_node.global_transform.basis.y.normalized()
	physics_node.global_position = target_global_position + up_dir * rest_length


# ============================================================================
# MESH CENTER CALCULATION
# ============================================================================

static func _compute_local_center(
	root: Node3D
) -> Vector3:

	var combined: AABB = _gather_aabb(
		root,
		root
	)

	return combined.get_center()


static func _gather_aabb(
	current: Node,
	root: Node3D
) -> AABB:

	var result := AABB()
	var has_result: bool = false


	if current is MeshInstance3D:

		var xform: Transform3D = (
			root.global_transform.affine_inverse()
			* current.global_transform
		)

		result = xform * current.get_aabb()

		has_result = true


	for child in current.get_children():

		if child is Node3D:

			var child_aabb: AABB = _gather_aabb(
				child,
				root
			)

			if has_result:
				result = result.merge(child_aabb)
			else:
				result = child_aabb

			has_result = true


	return result
