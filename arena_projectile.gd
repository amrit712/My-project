extends Area3D
class_name ArenaProjectile


# ============================================================
# PROJECTILE DATA
# ============================================================

var velocity: Vector3 = Vector3.ZERO
var lifetime: float = 3.0

var ignore_body: Node = null
var on_hit: Callable = Callable()

var single_target: bool = true

var _elapsed: float = 0.0
var _has_hit: bool = false


# ============================================================
# READY
# ============================================================

func _ready():

	# Projectile itself does not need to be detectable
	# by other physics bodies.
	collision_layer = 0

	# Detect cars.
	# Cars are assumed to be on physics layer 1.
	collision_mask = 1

	body_entered.connect(_on_body_entered)


# ============================================================
# MOVEMENT / LIFETIME
# ============================================================

func _physics_process(delta):

	global_position += velocity * delta

	_elapsed += delta

	if _elapsed >= lifetime:
		queue_free()


# ============================================================
# COLLISION
# ============================================================

func _on_body_entered(body):

	# Don't hit the car that fired the projectile.
	if body == ignore_body:
		return

	# If this projectile already hit something,
	# don't process another target.
	if _has_hit and single_target:
		return

	# Only cars can be hit.
	if not body.is_in_group("cars"):
		return

	# Phased cars cannot be hit.
	if body.has_node("StatusEffects"):

		var status_effects = body.get_node("StatusEffects")

		if status_effects.has_status("phased"):
			return

	_has_hit = true

	print("PROJECTILE HIT: ", body.name)

	# Tell the ability what was hit.
	if on_hit.is_valid():
		on_hit.call(body)

	# Destroy projectile after the hit.
	if single_target:
		queue_free()


# ============================================================
# SPAWN PROJECTILE
# ============================================================

static func spawn(
	tree: SceneTree,
	from_transform: Transform3D,
	radius: float,
	spawn_velocity: Vector3,
	spawn_lifetime: float,
	spawn_ignore_body: Node,
	spawn_on_hit: Callable,
	spawn_single_target: bool = true
) -> ArenaProjectile:

	# --------------------------------------------------------
	# Create projectile
	# --------------------------------------------------------

	var proj := ArenaProjectile.new()

	proj.velocity = spawn_velocity
	proj.lifetime = spawn_lifetime
	proj.ignore_body = spawn_ignore_body
	proj.on_hit = spawn_on_hit
	proj.single_target = spawn_single_target


	# --------------------------------------------------------
	# Visual mesh
	# --------------------------------------------------------

	var mesh := MeshInstance3D.new()

	var sphere := SphereMesh.new()

	sphere.radius = radius
	sphere.height = radius * 2.0

	mesh.mesh = sphere

	proj.add_child(mesh)


	# --------------------------------------------------------
	# Collision shape
	# --------------------------------------------------------

	var shape := CollisionShape3D.new()

	var sphere_shape := SphereShape3D.new()

	sphere_shape.radius = radius

	shape.shape = sphere_shape

	proj.add_child(shape)


	# --------------------------------------------------------
	# Add projectile to current scene
	# --------------------------------------------------------

	tree.current_scene.add_child(proj)

	proj.global_transform = from_transform


	# --------------------------------------------------------
	# Return projectile to ability
	# --------------------------------------------------------

	return proj
