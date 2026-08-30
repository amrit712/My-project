extends Node
class_name CarAI

## Attach as a child node (name it "CarAI") on any car where is_player is
## false. Computes throttle/steer/brake values every physics frame - the
## SAME variables carcontroller.gd reads from Input when is_player is true.
## This is a simple v1: target-seeking + basic ability use, no pathfinding
## or wall avoidance yet.

@export var vision_range: float = 45.0
@export var steering_gain: float = 2.0     # how sharply it turns toward its target
@export var min_throttle: float = 0.3       # never fully stops, even mid-turn
@export var ability_check_interval: float = 1.5
@export var ability_use_range: float = 20.0
@export var arena_center: Vector3 = Vector3.ZERO   # fallback target if nothing's in range

# Public - carcontroller.gd reads these instead of Input.get_axis() when
# this node is present.
var throttle_input: float = 0.0
var steer_input: float = 0.0
var braking: bool = false

var _car: Node = null
var _target: Node = null
var _ability_timer: float = 0.0

func _ready():
	_car = get_parent()

func _physics_process(delta):
	if _car == null or ("destroyed" in _car and _car.destroyed):
		throttle_input = 0.0
		steer_input = 0.0
		braking = true
		return

	_update_target()
	_compute_driving_input()
	_maybe_use_ability(delta)

func _update_target():
	_target = null

	var effective_vision_range = vision_range
	if _car.has_node("StatusEffects") and _car.get_node("StatusEffects").has_status("blinded"):
		# Blindness impairs a bot's SENSING, not its vision in a literal
		# screen-space sense (bots don't render/see pixels) - drastically
		# shrinking effective vision range achieves the same practical
		# effect: it can't reliably find/track a target while blinded.
		effective_vision_range = vision_range * 0.2

	var closest_dist = effective_vision_range
	for car in _car.get_tree().get_nodes_in_group("cars"):
		if car == _car:
			continue
		if not car.can_take_collision_damage():
			continue
		if "team_id" in car and "team_id" in _car and car.team_id == _car.team_id:
			continue  # don't target allies
		var dist = car.global_position.distance_to(_car.global_position)
		if dist < closest_dist:
			_target = car
			closest_dist = dist

func _compute_driving_input():
	var target_pos: Vector3 = arena_center
	if _target != null and is_instance_valid(_target):
		target_pos = _target.global_position

	var to_target = target_pos - _car.global_position
	to_target.y = 0.0
	if to_target.length() < 0.5:
		throttle_input = 0.0
		steer_input = 0.0
		braking = false
		return
	to_target = to_target.normalized()

	var forward = -_car.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	# Signed angle between where the car is facing and where it needs to
	# go - positive/negative tells us which way to steer.
	var angle = forward.signed_angle_to(to_target, Vector3.UP)
	steer_input = clamp(-angle * steering_gain, -1.0, 1.0)

	# Slow down for sharp turns instead of always flooring it - keeps the
	# bot from constantly overshooting and fighting its own steering.
	var alignment = forward.dot(to_target)
	throttle_input = clamp(lerp(min_throttle, 1.0, alignment), min_throttle, 1.0)
	braking = false

func _maybe_use_ability(delta):
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	_ability_timer = ability_check_interval

	if _target == null or not is_instance_valid(_target):
		return
	if _target.global_position.distance_to(_car.global_position) > ability_use_range:
		return

	# Deliberately dumb for v1: just tries Ability 1 whenever a target is
	# in range and it's off cooldown. Expand this later (Ability 2,
	# Ultimate, smarter target/range checks per ability type) once this
	# baseline is working.
	var ability1 = AbilityBase.find_ability(_car, AbilityBase.Slot.ABILITY_1)
	if ability1 and ability1.can_activate(_car):
		ability1.try_activate(_car)
