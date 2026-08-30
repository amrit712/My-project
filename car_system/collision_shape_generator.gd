class_name CollisionShapeGenerator
extends RefCounted

## Builds a convex collision shape from the car body's ACTUAL mesh geometry,
## instead of relying on one fixed generic box shared by every subclass.
## Convex is the right choice here, not just a simplification - VehicleBody3D
## (like all RigidBody3D-based physics) needs convex collision to behave
## correctly; a full concave/trimesh shape isn't reliably usable for a
## dynamic physics body anyway.
##
## IMPORTANT: call this AFTER WheelAttacher.attach_wheel_meshes() has
## already run. By that point the wheel meshes have been reparented out of
## body_instance onto the chassis's VehicleWheel3D nodes, so they're
## automatically excluded from the body's collision shape - which is
## correct, since wheels already have their own separate collision via the
## suspension raycasts.

static func fit_collision_to_body(car: Node, body_instance: Node):
	var collision_shape_node: CollisionShape3D = car.get_node_or_null("CollisionShape3D")
	if collision_shape_node == null:
		push_warning("CollisionShapeGenerator: car has no CollisionShape3D node")
		return

	var points = _gather_points(body_instance, collision_shape_node)
	if points.is_empty():
		push_warning("CollisionShapeGenerator: no mesh vertices found to generate collision from")
		return

	var convex_shape := ConvexPolygonShape3D.new()
	convex_shape.points = points
	collision_shape_node.shape = convex_shape

static func _gather_points(root: Node, reference: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()

	if root is MeshInstance3D and root.mesh != null:
		var mesh: Mesh = root.mesh
		# Every point gets expressed relative to the CollisionShape3D node
		# itself (not just the chassis root), so this works correctly even
		# if that node has its own offset transform.
		var xform: Transform3D = reference.global_transform.affine_inverse() * root.global_transform
		for surface_idx in range(mesh.get_surface_count()):
			var arrays = mesh.surface_get_arrays(surface_idx)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in verts:
				points.append(xform * v)

	for child in root.get_children():
		if child is Node3D:
			points.append_array(_gather_points(child, reference))

	return points
