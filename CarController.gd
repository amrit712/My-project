extends VehicleBody3D

@export var is_player := true
@export var team_id: int = 0
@export var car_class_name: String = ""

@export var max_rpm: float = 1200.0
@export var max_torque: float = 4000.0
@export var max_steering: float = 0.5
@export var steering_speed: float = 8.0
@export var brake_force: float = 60.0
@export var reverse_brake_force: float = 40.0
@export var throttle_smoothing: float = 6.0
@export var kill_mana_bonus: float = 25.0

@export var center_of_mass_offset: Vector3 = Vector3(0, -0.3, 0)
# ============================================================
# LOOP PHYSICS
# ============================================================

@export_category("Loop Physics")

@export var loop_radius: float = 40.0
@export var loop_body: StaticBody3D

@export var loop_detection_distance: float = 3.0

@export var loop_alignment_strength: float = 1200.0
@export var loop_alignment_damping: float = 150.0

var loop_active := false
var loop_center := Vector3.ZERO
var loop_axis := Vector3.UP

# ============================================================
# SELF RIGHTING
# ============================================================

@export_category("Self Righting")

@export var self_right_poll_interval: float = 0.25
@export var self_right_stationary_linear_threshold: float = 1.0
@export var self_right_stationary_angular_threshold: float = 0.5

@export var self_right_delay: float = 0.8
@export var self_right_torque: float = 3500.0
@export var self_right_damping: float = 250.0
@export var self_right_max_speed: float = 2.5
@export var self_right_lift_impulse: float = 6.0



const EXPLOSION_SCENE = preload("res://VFX/explosion/BigExplosionScene.tscn")


enum CarClass {
	ALL_ROUNDER,
	BASTION,
	NITRO,
	ENGINEER,
	HAVOC
}

@export var car_class: CarClass = CarClass.ALL_ROUNDER


enum CarState {
	ALIVE,
	WRECK
}


const FLIPPED_THRESHOLD := 0.3
const UPRIGHT_ALIGNMENT_TARGET := 0.97


var state = CarState.ALIVE
var destroyed := false

var previous_velocity: Vector3
var current_throttle: float = 0.0
# ============================================================
# BOOST
# ============================================================

var boost_active := false
var boost_timer: float = 0.0
var boost_acceleration: float = 0.0

var self_right_timer := 0.0
var is_righting := false
var self_right_fallback_axis := Vector3.ZERO

var _poll_timer: float = 0.0
var _stuck_poll_count: int = 0


# Current surface normal.
# Ground = UP
# Wall = LEFT/RIGHT
# Ceiling = DOWN



@onready var back_left: VehicleWheel3D = $"BACK-LEFT"
@onready var back_right: VehicleWheel3D = $"BACK-RIGHT"

@onready var cam: Camera3D = $Camera3D
@onready var health = $Health
@onready var mana: Node = $Mana
@onready var cam_shake: CameraShake = $Camera3D/CameraShake

@onready var passive_slot: Node = $PassiveBase
@onready var ability1_slot: Node = $Ability1
@onready var ability2_slot: Node = $Ability2
@onready var ultimate_slot: Node = $Ultimate


# ============================================================
# CLASS SETUP
# ============================================================

func setup_class():
	match car_class:

		CarClass.NITRO:
			passive_slot.set_script(load("res://CLASSES/NITRO/nitro_momentum_engine.gd"))
			ability1_slot.set_script(load("res://CLASSES/NITRO/nitro_phase_shift.gd"))
			ability2_slot.set_script(load("res://CLASSES/NITRO/nitro_sonic_decoy.gd"))
			ultimate_slot.set_script(load("res://CLASSES/NITRO/nitro_overdrive_barrage.gd"))

		CarClass.BASTION:
			passive_slot.set_script(load("res://CLASSES/BASTION/bastion_fortified_chassis.gd"))
			ability1_slot.set_script(load("res://CLASSES/BASTION/bastion_deployable_bunker.gd"))
			ability2_slot.set_script(load("res://CLASSES/BASTION/bastion_reinforced_charge.gd"))
			ultimate_slot.set_script(load("res://CLASSES/BASTION/bastion_immovable_object.gd"))

		CarClass.ENGINEER:
			passive_slot.set_script(load("res://CLASSES/ENGINEER/engineer_salvage.gd"))
			ability1_slot.set_script(load("res://CLASSES/ENGINEER/engineer_repair_link.gd"))
			ability2_slot.set_script(load("res://CLASSES/ENGINEER/engineer_energy_drain.gd"))
			ultimate_slot.set_script(load("res://CLASSES/ENGINEER/engineer_inheritance_protocol.gd"))

		CarClass.HAVOC:
			passive_slot.set_script(load("res://CLASSES/HAVOC/havoc_thermal_amplifier.gd"))
			ability1_slot.set_script(load("res://CLASSES/HAVOC/havoc_napalm_trail.gd"))
			ability2_slot.set_script(load("res://CLASSES/HAVOC/havoc_concussive_burst.gd"))
			ultimate_slot.set_script(load("res://CLASSES/HAVOC/havoc_scorched_earth.gd"))

		CarClass.ALL_ROUNDER:
			passive_slot.set_script(load("res://CLASSES/ALL_ROUNDER/allrounder_fluid_driver.gd"))
			ability1_slot.set_script(load("res://CLASSES/ALL_ROUNDER/allrounder_tracker_dart.gd"))
			ability2_slot.set_script(load("res://CLASSES/ALL_ROUNDER/allrounder_quick_patch.gd"))
			ultimate_slot.set_script(load("res://CLASSES/ALL_ROUNDER/allrounder_apex_mode.gd"))


signal eliminated(killer: Node, victim: Node)

var kills := 0
func update_loop_physics(delta: float) -> void:

	if loop_body == null:
		return


	# ========================================================
	# LOOP CENTER
	# ========================================================

	var center := loop_body.global_position


	# ========================================================
	# LOOP AXIS
	# ========================================================
	#
	# Assumes the torus lies in the XZ plane.
	# Therefore its axis is local Y.

	var axis := (
		loop_body.global_transform.basis.y
	).normalized()


	# ========================================================
	# POSITION RELATIVE TO LOOP CENTER
	# ========================================================

	var relative := (
		global_position - center
	)


	# Remove the component along the loop axis.
	#
	# This leaves the position on the circular plane.

	var planar_position := (
		relative
		- axis * relative.dot(axis)
	)


	var distance_from_center := (
		planar_position.length()
	)


	# ========================================================
	# DETECT WHETHER WE ARE AT THE LOOP
	# ========================================================

	if absf(
		distance_from_center - loop_radius
	) > loop_detection_distance:

		loop_active = false
		return


	loop_active = true


	# ========================================================
	# RADIAL DIRECTION
	# ========================================================

	if planar_position.length_squared() < 0.001:
		return


	var outward := (
		planar_position.normalized()
	)


	# Direction toward loop center.

	var inward := -outward


	# ========================================================
	# TANGENT
	# ========================================================

	var tangent := (
		axis.cross(outward)
	).normalized()


	# Make tangent point in direction of travel.

	if linear_velocity.dot(tangent) < 0.0:
		tangent = -tangent


	# ========================================================
	# SPEED ALONG LOOP
	# ========================================================

	var speed := (
		linear_velocity.dot(tangent)
	)


	if speed < 0.0:
		speed = 0.0


	# ========================================================
	# CENTRIPETAL ACCELERATION
	# ========================================================

	var centripetal_acceleration := (
		speed * speed
		/ maxf(loop_radius, 0.01)
	)


	# ========================================================
	# GRAVITY
	# ========================================================

	var gravity := get_gravity()


	var gravity_inward := (
		gravity.dot(inward)
	)


	# ========================================================
	# REQUIRED TRACK ACCELERATION
	# ========================================================

	var required_acceleration := (
		centripetal_acceleration
		- gravity_inward
	)


	# ========================================================
	# NOT ENOUGH SPEED
	# ========================================================
	#
	# The track cannot pull the car.
	#
	# Therefore if the required normal force becomes
	# negative, the car loses contact.

	if required_acceleration <= 0.0:

		loop_active = false

		return


	# ========================================================
	# TRACK NORMAL FORCE
	# ========================================================

	var normal_force := (
		required_acceleration
		* mass
	)


	apply_central_force(
		inward
		* normal_force
	)


	# ========================================================
	# ROTATE CAR TO FOLLOW LOOP
	# ========================================================

	var car_up := (
		global_transform.basis.y
	)


	var target_up := outward


	var rotation_axis := (
		car_up.cross(target_up)
	)


	if rotation_axis.length_squared() > 0.0001:

		rotation_axis = (
			rotation_axis.normalized()
		)


		var alignment := clampf(
			car_up.dot(target_up),
			-1.0,
			1.0
		)


		var angle := acos(alignment)


		apply_torque(
			rotation_axis
			* angle
			* loop_alignment_strength
		)


	# Rotational damping.

	apply_torque(
		-angular_velocity
		* loop_alignment_damping
	)

# ============================================================
# SELF RIGHTING
# ============================================================

func get_upright_alignment() -> float:
	return global_transform.basis.y.dot(Vector3.UP)


func update_self_righting(delta: float):

	if destroyed:
		return

	# On a wall or ceiling, DOWN/UP relative to the world is not
	# a useful definition of "upside down". Let surface driving
	# control the orientation instead of self-righting.

	var alignment: float = (
		get_upright_alignment()
	)

	if is_righting:

		if alignment > UPRIGHT_ALIGNMENT_TARGET:

			is_righting = false
			self_right_timer = 0.0
			self_right_fallback_axis = Vector3.ZERO
			angular_velocity = Vector3.ZERO

			_stuck_poll_count = 0
			_poll_timer = 0.0

		else:

			apply_self_righting_torque()

		return


	_poll_timer += delta

	if _poll_timer < self_right_poll_interval:
		return

	_poll_timer = 0.0


	var is_stuck_flipped: bool = (
		alignment < FLIPPED_THRESHOLD
		and linear_velocity.length()
			< self_right_stationary_linear_threshold
		and angular_velocity.length()
			< self_right_stationary_angular_threshold
	)


	if is_stuck_flipped:

		_stuck_poll_count += 1

	else:

		_stuck_poll_count = 0


	var required_polls: int = max(
		1,
		int(
			ceil(
				self_right_delay
				/ self_right_poll_interval
			)
		)
	)


	if _stuck_poll_count >= required_polls:

		is_righting = true
		_stuck_poll_count = 0

		sleeping = false

		apply_central_impulse(
			Vector3.UP
			* self_right_lift_impulse
			* mass
		)

		print(
			name,
			" self-righting triggered"
		)


func apply_self_righting_torque():

	sleeping = false

	var up: Vector3 = global_transform.basis.y
	var world_up: Vector3 = Vector3.UP

	var torque_axis: Vector3 = (
		up.cross(world_up)
	)


	if torque_axis.length_squared() < 0.01:

		if self_right_fallback_axis == Vector3.ZERO:

			self_right_fallback_axis = (
				global_transform.basis.x
			)

		torque_axis = (
			self_right_fallback_axis
		)

	else:

		self_right_fallback_axis = Vector3.ZERO
		torque_axis = torque_axis.normalized()


	var alignment: float = clampf(
		up.dot(world_up),
		-1.0,
		1.0
	)

	var torque_strength: float = (
		self_right_torque
		* (1.0 - alignment)
	)

	apply_torque(
		torque_axis
		* torque_strength
	)

	apply_torque(
		-angular_velocity
		* self_right_damping
	)


	if angular_velocity.length() > self_right_max_speed:

		angular_velocity = (
			angular_velocity.normalized()
			* self_right_max_speed
		)


# ============================================================
# READY
# ============================================================

func _ready():

	center_of_mass_mode = (
		RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	)

	center_of_mass = center_of_mass_offset

	add_to_group("cars")

	contact_monitor = true
	max_contacts_reported = 8

	previous_velocity = linear_velocity

	health.died.connect(
		_on_car_destroyed
	)

	setup_class()

	ability1_slot.set_process(true)
	ability2_slot.set_process(true)
	ultimate_slot.set_process(true)


func can_take_collision_damage() -> bool:
	return state == CarState.ALIVE

# ============================================================
# START BOOST
# ============================================================
func start_boost(
	acceleration: float,
	duration: float = -1.0
) -> void:

	if destroyed:
		return

	boost_active = true
	boost_timer = duration
	boost_acceleration = acceleration

	sleeping = false

	print(
		"BOOST STARTED | acceleration: ",
		acceleration,
		" | duration: ",
		duration
	)
func stop_boost() -> void:

	if not boost_active:
		return

	boost_active = false
	boost_timer = 0.0
	boost_acceleration = 0.0

	print("BOOST ENDED")
# ============================================================
# UPDATE BOOST
# ============================================================

# ============================================================
# UPDATE BOOST
# ============================================================

func update_boost(delta: float) -> void:

	if not boost_active:
		return


	# --------------------------------------------------------
	# COUNT DOWN ONLY IF BOOST HAS A TIME LIMIT
	# --------------------------------------------------------

	if boost_timer > 0.0:

		boost_timer -= delta

		if boost_timer <= 0.0:

			stop_boost()

			return


	# --------------------------------------------------------
	# BOOST DIRECTION
	# --------------------------------------------------------
	#
	# Follow the car's CURRENT MOVEMENT direction.
	#
	# This preserves your existing behavior for:
	# - normal driving
	# - turning
	# - loops
	# - walls
	# - upside-down driving

	var direction: Vector3 = linear_velocity


	if direction.length_squared() > 0.01:

		direction = direction.normalized()

	else:

		direction = (
			-global_transform.basis.z
		).normalized()


	# --------------------------------------------------------
	# APPLY BOOST
	# --------------------------------------------------------

	apply_central_force(
		direction
		* boost_acceleration
		* mass
	)
# ============================================================
# PHYSICS
# ============================================================
func receive_ability(ability_type: int) -> void:

	match ability_type:

		0:
			print("ABILITY RECEIVED: HEAL")

		1:
			print("ABILITY RECEIVED: REVIVE")

		2:
			print("ABILITY RECEIVED: GAUGE SHIFT")
func _physics_process(delta):

	previous_velocity = linear_velocity


	if destroyed:

		back_left.engine_force = 0
		back_right.engine_force = 0

		back_left.brake = brake_force
		back_right.brake = brake_force


		if (
			linear_velocity.length() < 0.2
			and angular_velocity.length() < 0.2
		):

			sleeping = true

		return


	var car_ai: Node = (
		get_node_or_null("CarAI")
	)


	if is_player or car_ai != null:

		var steer_input: float
		var throttle_input: float
		var braking: bool


		if is_player:

			steer_input = Input.get_axis(
				"RIGHT",
				"LEFT"
			)

			throttle_input = Input.get_axis(
				"BACKWARD",
				"FORWARD"
			)

			braking = Input.is_action_pressed(
				"BRAKE"
			)

		else:

			steer_input = car_ai.steer_input
			throttle_input = car_ai.throttle_input
			braking = car_ai.braking


		# ----------------------------------------------------
		# STEERING
		# ----------------------------------------------------

		steering = lerp(
			steering,
			steer_input * max_steering,
			steering_speed * delta
		)


		# ----------------------------------------------------
		# THROTTLE
		# ----------------------------------------------------

		current_throttle = move_toward(
			current_throttle,
			throttle_input,
			throttle_smoothing * delta
		)


		# ----------------------------------------------------
		# RPM
		# ----------------------------------------------------

		var avg_rpm: float = (
			back_left.get_rpm()
			+ back_right.get_rpm()
		) * 0.5


		var manual_brake: float = 0.0
		var engine_output: float = 0.0


		if braking:

			manual_brake = brake_force

		elif (
			sign(current_throttle) != 0
			and sign(avg_rpm) != 0
			and sign(current_throttle)
				!= sign(avg_rpm)
			and absf(avg_rpm) > 50.0
		):

			manual_brake = reverse_brake_force

		else:

			engine_output = (
				current_throttle
				* max_torque
			)


		back_left.brake = manual_brake
		back_right.brake = manual_brake
		update_loop_physics(delta)
		

		# ----------------------------------------------------
		# ENGINE POWER
		# ----------------------------------------------------

		var power: float = clampf(
			1.0
			- absf(avg_rpm) / max_rpm,
			0.0,
			1.0
		)


		var final_force: float = (
			engine_output
			* power
		)


		back_left.engine_force = final_force
		back_right.engine_force = final_force



		# ----------------------------------------------------
		# CAMERA
		# ----------------------------------------------------

		var speed: float = (
			linear_velocity.length()
		)

		cam.fov = lerp(
			cam.fov,
			clampf(
				75.0 + speed * 0.35,
				75.0,
				90.0
			),
			5.0 * delta
		)

		update_self_righting(
			delta
		)
		update_boost(delta)


# ============================================================
# INPUT
# ============================================================

func _input(event):

	if event.is_action_pressed(
		"ui_accept"
	):

		health.take_damage(20)


	if not is_player:
		return


	if event.is_action_pressed(
		"ABILITY1"
	):

		if ability1_slot is AbilityBase:

			ability1_slot.try_activate(
				self
			)


	if event.is_action_pressed(
		"ABILITY2"
	):

		if ability2_slot is AbilityBase:

			ability2_slot.try_activate(
				self
			)


	if event.is_action_pressed(
		"ULTIMATE"
	):

		if ultimate_slot is AbilityBase:

			ultimate_slot.try_activate(
				self
			)


# ============================================================
# EXPLOSION
# ============================================================

func spawn_explosion() -> void:

	if EXPLOSION_SCENE == null:

		push_error(
			"Explosion scene is NULL!"
		)

		return


	var explosion := (
		EXPLOSION_SCENE.instantiate()
	)


	if not explosion is Node3D:

		push_error(
			"Explosion root must be Node3D"
		)

		explosion.queue_free()

		return


	get_tree().current_scene.add_child(
		explosion
	)


	var spawn_point := (
		get_node_or_null(
			"ExplosionSpawnPoint"
		)
	)


	if spawn_point:

		explosion.global_position = (
			spawn_point.global_position
		)

	else:

		explosion.global_position = (
			global_position
			+ Vector3.UP * 0.8
		)


	print(
		"Explosion spawned at: ",
		explosion.global_position
	)


# ============================================================
# DESTRUCTION
# ============================================================

func _on_car_destroyed(
	killer: Node = null
):

	if state == CarState.WRECK:
		return


	state = CarState.WRECK
	destroyed = true

	spawn_explosion()


	if is_player:

		cam_shake.add_trauma(
			0.8
		)


	if (
		killer
		and killer != self
		and is_instance_valid(killer)
		and "kills" in killer
	):

		killer.kills += 1


		if killer.has_node("Mana"):

			killer.get_node(
				"Mana"
			).add_mana(
				kill_mana_bonus
			)


		print(
			killer.name,
			" eliminated ",
			name
		)

	else:

		killer = null

		print(
			name,
			" was destroyed"
		)


	eliminated.emit(
		killer,
		self
	)
