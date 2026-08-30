extends Node3D
class_name CameraShake

@export var max_offset: Vector3 = Vector3(0.3, 0.3, 0.0)
@export var max_rotation: Vector3 = Vector3(0.05, 0.05, 0.05)
@export var trauma_decay: float = 1.5
@export var noise_speed: float = 20.0

var trauma: float = 0.0
var _noise := FastNoiseLite.new()
var _noise_time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _seed_offset: Vector3
var _base_rotation: Vector3

@onready var camera: Camera3D = get_parent() as Camera3D

func _ready():
	_rng.randomize()
	_noise.seed = _rng.randi()
	_noise.frequency = 1.0
	_seed_offset = Vector3(_rng.randf_range(0, 1000), _rng.randf_range(0, 1000), _rng.randf_range(0, 1000))
	if camera:
		_base_rotation = camera.rotation  # remember the camera's real configured angle

func add_trauma(amount: float):
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta):
	if !camera:
		return

	if trauma <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		camera.rotation = _base_rotation   # rest exactly at the real angle, not (0,0,0)
		return

	_noise_time += delta * noise_speed
	var shake_amount = trauma * trauma

	var offset_x = _noise.get_noise_2d(_noise_time + _seed_offset.x, 0.0) * max_offset.x * shake_amount
	var offset_y = _noise.get_noise_2d(_noise_time + _seed_offset.y, 100.0) * max_offset.y * shake_amount
	var rot_x = _noise.get_noise_2d(_noise_time + _seed_offset.x, 200.0) * max_rotation.x * shake_amount
	var rot_y = _noise.get_noise_2d(_noise_time + _seed_offset.y, 300.0) * max_rotation.y * shake_amount
	var rot_z = _noise.get_noise_2d(_noise_time + _seed_offset.z, 400.0) * max_rotation.z * shake_amount

	camera.h_offset = offset_x
	camera.v_offset = offset_y
	camera.rotation = _base_rotation + Vector3(rot_x, rot_y, rot_z)  # additive, not absolute

	trauma = max(0.0, trauma - trauma_decay * delta)
