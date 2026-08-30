extends Node3D
enum AbilityType {
	HEAL,
	REVIVE,
	GAUGE_SHIFT
}

var ability_type: AbilityType
# ============================================================
# PROCEDURAL ABILITY ORB
# GODOT 4
#
# Structural graph + ambient particles + final energy burst
# ============================================================


# ============================================================
# SETTINGS
# ============================================================

@export_category("Orb")

@export var orb_radius: float = 2.5

@export var creation_time: float = 10.0


@export_category("Energy Network")

@export var point_count: int = 70

@export var starting_radius: float = 5.0

@export var connection_distance: float = 2.0

@export var max_connections: int = 3


@export_category("Ambient Particles")

@export var ambient_particle_count: int = 100

@export var ambient_radius: float = 7.0


@export_category("Visuals")

@export var point_size: float = 0.09

@export var line_width: float = 0.025
var connection_update_timer: float = 0.0

@export var connection_update_interval: float = 0.15


# ============================================================
# VARIABLES
# ============================================================

var points: Array[Dictionary] = []

var ambient_particles: Array[Dictionary] = []

var orb: MeshInstance3D

var elapsed: float = 0.0

var finished: bool = false

var burst_time: float = -1.0
@onready var collision_area: Area3D = $CollisionArea

# ============================================================
# READY
# ============================================================

func _ready() -> void:
	
	collision_area.monitoring = false
	collision_area.body_entered.connect(
		_on_collision_area_body_entered
	)

	randomize()

	ability_type = randi_range(
		0,
		2
	)

	create_orb()

	create_structural_points()

	create_ambient_particles()

func get_ability_color() -> Color:

	match ability_type:

		AbilityType.HEAL:
			return Color(
				0.1,
				1.0,
				0.25
			)

		AbilityType.REVIVE:
			return Color(
				0.75,
				0.15,
				1.0
			)

		AbilityType.GAUGE_SHIFT:
			return Color(
				0.05,
				0.45,
				1.0
			)

	return Color.WHITE
func _on_collision_area_body_entered(
	body: Node3D
) -> void:

	print("ABILITY ORB TOUCHED BY: ", body.name)
	if body.has_method("receive_ability"):
		body.receive_ability(ability_type)

		queue_free()
# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	elapsed += delta

	var progress: float = clamp(
		elapsed / creation_time,
		0.0,
		1.0
	)

	update_structural_points(progress)

	connection_update_timer += delta

	if connection_update_timer >= connection_update_interval:
		connection_update_timer = 0.0
		update_connections()

	update_ambient_particles(progress)

	update_orb(progress)



# ============================================================
# CREATE ORB
# ============================================================

func create_orb() -> void:

	orb = MeshInstance3D.new()

	var mesh := SphereMesh.new()

	mesh.radius = orb_radius

	mesh.height = orb_radius * 2.0

	mesh.radial_segments = 12

	mesh.rings = 6

	orb.mesh = mesh

	orb.scale = Vector3.ZERO

	var material := StandardMaterial3D.new()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var ability_color: Color = get_ability_color()

	material.albedo_color = ability_color

	material.emission_enabled = true

	material.emission = ability_color

	material.emission_energy_multiplier = 4.0

	orb.material_override = material

	add_child(orb)


# ============================================================
# CREATE STRUCTURAL POINTS
# ============================================================

func create_structural_points() -> void:
	var ability_color: Color = get_ability_color()
	for i in range(point_count):

		var mesh_instance := MeshInstance3D.new()

		var mesh := SphereMesh.new()

		mesh.radius = point_size

		mesh.height = point_size * 2.0

		mesh.radial_segments = 6

		mesh.rings = 3

		mesh_instance.mesh = mesh

		var material := StandardMaterial3D.new()

		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		material.albedo_color = ability_color

		material.emission_enabled = true
		material.emission = ability_color

		material.emission_energy_multiplier = 6.0

		mesh_instance.material_override = material

		var start_direction := random_direction()

		var start_position := (
			start_direction
			* starting_radius
			* randf_range(0.7, 1.2)
		)

		mesh_instance.position = start_position

		var target_direction := random_direction()

		var target_position := (
			target_direction
			* orb_radius
		)

		add_child(mesh_instance)

		points.append({
			"node": mesh_instance,
			"start": start_position,
			"target": target_position,
			"phase": randf() * 100.0
		})


# ============================================================
# CREATE AMBIENT PARTICLES
# ============================================================

func create_ambient_particles() -> void:
	var ability_color: Color = get_ability_color()
	for i in range(ambient_particle_count):

		var particle := MeshInstance3D.new()

		var mesh := SphereMesh.new()

		var size := randf_range(
			0.025,
			0.065
		)

		mesh.radius = size

		mesh.height = size * 2.0

		mesh.radial_segments = 5

		mesh.rings = 2

		particle.mesh = mesh

		var material := StandardMaterial3D.new()

		material.shading_mode = (
			BaseMaterial3D.SHADING_MODE_UNSHADED
		)

		material.albedo_color = ability_color



		material.emission_enabled = true

		material.emission = ability_color

		material.emission_energy_multiplier = 4.0

		particle.material_override = material

		var direction := random_direction()

		var distance := randf_range(
			2.0,
			ambient_radius
		)

		particle.position = (
			direction * distance
		)

		add_child(particle)

		ambient_particles.append({
			"node": particle,
			"phase": randf() * 100.0,
			"speed": randf_range(0.5, 1.5),
			"radius": distance
		})


# ============================================================
# UPDATE STRUCTURAL POINTS
# ============================================================

func update_structural_points(
	progress: float
) -> void:

	for data in points:

		var node: MeshInstance3D = data["node"]

		var start: Vector3 = data["start"]

		var target: Vector3 = data["target"]

		var phase: float = data["phase"]

		var smooth_progress: float = (
			progress
			* progress
			* (3.0 - 2.0 * progress)
		)

		var position: Vector3 = start.lerp(
			target,
			smooth_progress
		)

		# ----------------------------------------------------
		# Chaotic movement
		# ----------------------------------------------------

		var chaos: float = (
			1.0 - smooth_progress
		)

		var random_motion := Vector3(
			sin(elapsed * 3.0 + phase),
			cos(elapsed * 2.7 + phase),
			sin(elapsed * 2.3 + phase * 1.7)
		)

		random_motion *= (
			chaos * 0.8
		)

		node.position = (
			position
			+ random_motion
		)


# ============================================================
# UPDATE CONNECTION GRAPH
# ============================================================

func update_connections() -> void:

	# Remove previous graph lines

	for child in get_children():

		if child.is_in_group(
			"orb_connection"
		):

			child.queue_free()


	for i in range(points.size()):

		var point_a: MeshInstance3D = (
			points[i]["node"]
		)

		var candidates: Array[Dictionary] = []

		for j in range(points.size()):

			if i == j:
				continue

			var point_b: MeshInstance3D = (
				points[j]["node"]
			)

			var distance: float = (
				point_a.position
				- point_b.position
			).length()

			if distance <= connection_distance:

				candidates.append({
					"node": point_b,
					"distance": distance,
					"index": j
				})


		candidates.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				return a["distance"] < b["distance"]
		)


		var connections: int = 0

		for candidate in candidates:

			if connections >= max_connections:
				break

			var j: int = candidate["index"]

			if j < i:
				continue

			create_connection(
				point_a.position,
				candidate["node"].position
			)

			connections += 1


# ============================================================
# CREATE CONNECTION
# ============================================================

func create_connection(
	a: Vector3,
	b: Vector3
) -> void:

	var line := MeshInstance3D.new()

	line.add_to_group(
		"orb_connection"
	)

	var cylinder := CylinderMesh.new()

	var direction: Vector3 = b - a

	var length: float = direction.length()

	cylinder.height = length

	cylinder.top_radius = line_width

	cylinder.bottom_radius = line_width

	cylinder.radial_segments = 6

	line.mesh = cylinder

	line.position = (
		a + b
	) * 0.5

	line.quaternion = Quaternion(
		Vector3.UP,
		direction.normalized()
	)

	var material := StandardMaterial3D.new()

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	var ability_color: Color = get_ability_color()

	material.albedo_color = ability_color



	material.emission_enabled = true

	material.emission = ability_color

	material.emission_energy_multiplier = 5.0

	line.material_override = material

	add_child(line)


# ============================================================
# AMBIENT PARTICLE MOVEMENT
# ============================================================

func update_ambient_particles(
	progress: float
) -> void:

	for data in ambient_particles:

		var particle: MeshInstance3D = (
			data["node"]
		)

		var phase: float = data["phase"]

		var speed: float = data["speed"]

		var original_radius: float = (
			data["radius"]
		)

		var chaos: float = (
			1.0 - progress
		)

		# ----------------------------------------------------
		# Orbital movement
		# ----------------------------------------------------

		var angle: float = (
			elapsed
			* speed
			+ phase
		)

		var radius: float = (
			original_radius
			* (0.6 + chaos * 0.4)
		)

		var orbit := Vector3(
			cos(angle) * radius,
			sin(angle * 1.3 + phase) * radius * 0.5,
			sin(angle) * radius
		)

		# ----------------------------------------------------
		# Random floating motion
		# ----------------------------------------------------

		var drift := Vector3(
			sin(elapsed * 1.7 + phase),
			cos(elapsed * 1.4 + phase),
			sin(elapsed * 2.1 + phase)
		)

		drift *= (
			chaos * 0.8
		)

		var position := (
			orbit + drift
		)

		# ----------------------------------------------------
		# Pull toward orb
		# ----------------------------------------------------

		var pull: float = (
			progress
			* progress
		)

		position = position.lerp(
			Vector3.ZERO,
			pull * 0.75
		)

		particle.position = position

		# ----------------------------------------------------
		# Flicker
		# ----------------------------------------------------

		var pulse: float = (
			0.7
			+ 0.3
			* sin(
				elapsed * 5.0
				+ phase
			)
		)

		particle.scale = Vector3.ONE * pulse


# ============================================================
# ORB FORMATION
# ============================================================

func update_orb(
	progress: float
) -> void:

	var orb_progress: float = clamp(
		(progress - 0.55)
		/ 0.45,
		0.0,
		1.0
	)

	var smooth: float = (
		orb_progress
		* orb_progress
		* (3.0 - 2.0 * orb_progress)
	)

	orb.scale = (
		Vector3.ONE
		* smooth
	)

	orb.rotation.y += 0.01

	# --------------------------------------------------------
	# Trigger burst
	# --------------------------------------------------------

	if (
		progress >= 1.0
		and not finished
	):

		finished = true

		burst_time = elapsed

		create_final_burst()
		collision_area.monitoring = true


# ============================================================
# FINAL ENERGY BURST
# ============================================================

func create_final_burst() -> void:

	for i in range(80):

		var particle := MeshInstance3D.new()

		var mesh := SphereMesh.new()

		var size := randf_range(
			0.025,
			0.07
		)

		mesh.radius = size

		mesh.height = size * 2.0

		mesh.radial_segments = 5

		mesh.rings = 2

		particle.mesh = mesh

		var material := StandardMaterial3D.new()

		material.shading_mode = (
			BaseMaterial3D.SHADING_MODE_UNSHADED
		)

		material.albedo_color = Color(
			0.1,
			0.8,
			1.0
		)

		material.emission_enabled = true

		material.emission = Color(
			0.0,
			0.8,
			1.0
		)

		material.emission_energy_multiplier = 8.0

		particle.material_override = material

		particle.position = Vector3.ZERO

		add_child(particle)

		var direction := random_direction()

		var speed := randf_range(
			4.0,
			9.0
		)

		var lifetime := randf_range(
			0.5,
			1.2
		)

		var tween := create_tween()

		tween.set_parallel(true)

		tween.tween_property(
			particle,
			"position",
			direction * speed,
			lifetime
		)

		tween.tween_property(
			particle,
			"scale",
			Vector3.ZERO,
			lifetime
		)

		tween.chain().tween_callback(
			particle.queue_free
		)


# ============================================================
# RANDOM DIRECTION
# ============================================================

func random_direction() -> Vector3:

	var direction := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)

	if direction.length() < 0.001:

		direction = Vector3(
			1.0,
			0.0,
			0.0
		)

	return direction.normalized()
