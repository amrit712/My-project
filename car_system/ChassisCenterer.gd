class_name ChassisCenterer
extends RefCounted

## Centers the car body mesh on the chassis. Two modes, same pattern as
## WheelAttacher's position handling:
## - Manual override (subclass_data.override_body_position): trust a
##   typed value directly - use this if a model's own pivot is unreliable
##   or includes extra geometry that throws off auto-detection.
## - Auto-detect (default): computes the body mesh's true AABB center and
##   offsets it so it sits correctly regardless of where the model's own
##   origin was set.
##
## Only X/Z (horizontal) are auto-corrected - Y is left alone by default,
## since a vertical offset is usually intentional (ride height relative
## to the wheels) and silently "fixing" it would fight your suspension
## setup rather than help it.

static func center_body(body_instance: Node3D, subclass_data: CarSubclassData = null):
	if subclass_data != null and subclass_data.override_body_position:
		body_instance.position = subclass_data.body_position_offset
	else:
		var local_center = _compute_local_center(body_instance)
		body_instance.position = Vector3(-local_center.x, 0.0, -local_center.z)

	# Applied on top of EITHER method above - lets you nudge ride height
	# without needing to know or replicate the auto-detected X/Z values.
	if subclass_data != null:
		body_instance.position.y += subclass_data.body_vertical_offset

static func _compute_local_center(root: Node3D) -> Vector3:
	var combined := _gather_aabb(root, root)
	return combined.get_center()

static func _gather_aabb(current: Node, root: Node3D) -> AABB:
	var result := AABB()
	var has_result := false

	if current is MeshInstance3D:
		var xform: Transform3D = root.global_transform.affine_inverse() * current.global_transform
		result = xform * current.get_aabb()
		has_result = true

	for child in current.get_children():
		if child is Node3D:
			var child_aabb = _gather_aabb(child, root)
			result = child_aabb if not has_result else result.merge(child_aabb)
			has_result = true

	return result
