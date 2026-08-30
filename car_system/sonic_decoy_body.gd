extends Node3D
class_name SonicDecoyBody

## A ghost copy of the car that mirrors the SAME live input the real player
## is currently pressing, for as long as it lives. Movement is simple
## kinematic (position/rotation updates, no real wheel physics) since it
## just needs to LOOK like it's driving convincingly, not actually be a
## physics-simulated car.

signal hit_by_enemy(attacker: Node)

var owner_car: Node = null
var lifetime: float = 4.0
var move_speed: float = 22
var turn_speed: float = 2.0     # radians/sec at full steer input

# Change this to match whichever physics layer your cars actually use -
# same bit as CARS_COLLISION_LAYER_BIT in nitro_phase_shift.gd.
const CARS_COLLISION_LAYER_BIT := 2

var _elapsed: float = 0.0
var _hit_area: Area3D

func _ready():
	_hit_area = Area3D.new()
	add_child(_hit_area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 1.2, 4.0)   # roughly car-sized - adjust to match your model
	shape.shape = box
	_hit_area.add_child(shape)

	# CRITICAL: a fresh Area3D.new() defaults to layer 1 / mask 1 - but
	# cars live on their own dedicated layer now. Without explicitly
	# setting this, the area structurally cannot detect cars at all,
	# regardless of anything else being correct.
	_hit_area.collision_layer = 0
	_hit_area.set_collision_mask_value(CARS_COLLISION_LAYER_BIT, true)

	_hit_area.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return

	# Reads the SAME global Input state the real player is using right
	# now - not a one-time snapshot taken at spawn, a live read every
	# frame. This is what makes "press W and both cars move forward" work.
	var throttle_input = Input.get_axis("BACKWARD", "FORWARD")
	var steer_input = Input.get_axis("RIGHT", "LEFT")

	rotate_y(steer_input * turn_speed * delta)
	var forward = -global_transform.basis.z

	# Mirror the REAL car's actual current speed instead of a fixed
	# constant, so the decoy always matches your pace exactly rather than
	# potentially running away from or lagging behind you.
	var target_speed = 0.0
	if is_instance_valid(owner_car):
		target_speed = owner_car.linear_velocity.length()

	global_position += forward * sign(throttle_input) * target_speed * delta

func _on_body_entered(body):
	if body == owner_car:
		return
	if not body.is_in_group("cars"):
		return
	hit_by_enemy.emit(body)
