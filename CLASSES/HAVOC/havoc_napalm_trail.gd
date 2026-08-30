extends AbilityBase
class_name HavocNapalmTrail

# Ability 1 - Napalm Trail
# While active (4s), drops fire segments behind Havoc as it drives. Each
# segment lasts 6s, damages enemies standing in it, and pauses their mana/
# health regen for 2s after they leave. Overlapping segments burn out
# faster so Havoc can't stack infinite uptime by circling in place.

@export var emit_duration: float = 4.0
@export var segment_interval: float = 0.3
@export var segment_lifetime: float = 6.0
@export var segment_radius: float = 2.0
@export var damage_per_second: int = 8
@export var regen_pause_duration: float = 2.0

func _init():
	slot = Slot.ABILITY_1
	cooldown = 18.0
	mana_cost = 20

var _emitting: bool = false
var _emit_timer: float = 0.0
var _segment_timer: float = 0.0
var _active_segments: Array = []

func activate(caster):
	_emitting = true
	_emit_timer = emit_duration
	_segment_timer = 0.0
	print(caster.name, " ignites Napalm Trail")

func _physics_process(delta):
	if !_emitting:
		return
	var caster = get_parent()
	_emit_timer -= delta
	_segment_timer -= delta
	if _segment_timer <= 0.0:
		_drop_segment(caster)
		_segment_timer = segment_interval
	if _emit_timer <= 0.0:
		_emitting = false

func _drop_segment(caster):
	var segment := Area3D.new()
	segment.name = "NapalmSegment"

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = segment_radius
	cyl.height = 1.0
	shape.shape = cyl
	segment.add_child(shape)

	var mesh := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = segment_radius
	cyl_mesh.bottom_radius = segment_radius
	cyl_mesh.height = 0.1
	mesh.mesh = cyl_mesh
	segment.add_child(mesh)

	caster.get_tree().current_scene.add_child(segment)
	segment.global_position = caster.global_position

	var lifetime = segment_lifetime
	for other in _active_segments:
		if is_instance_valid(other) and other.global_position.distance_to(segment.global_position) < segment_radius * 1.5:
			lifetime *= 0.5
			break
	_active_segments.append(segment)

	var bodies_in_segment: Dictionary = {}
	segment.body_entered.connect(func(body):
		if body.is_in_group("cars"):
			bodies_in_segment[body.get_instance_id()] = body
	)
	segment.body_exited.connect(func(body):
		if body.is_in_group("cars"):
			bodies_in_segment.erase(body.get_instance_id())
			if body.has_node("StatusEffects"):
				body.get_node("StatusEffects").apply_status("regen_paused", regen_pause_duration, 1.0)
	)

	_tick_segment(caster, segment, bodies_in_segment, lifetime)

func _tick_segment(caster, segment: Area3D, bodies_in_segment: Dictionary, lifetime: float):
	var tick_interval := 0.5
	var ticks_remaining := int(lifetime / tick_interval)
	for i in range(ticks_remaining):
		await segment.get_tree().create_timer(tick_interval).timeout
		if !is_instance_valid(segment):
			return
		for body in bodies_in_segment.values():
			if is_instance_valid(body) and body != caster and body.has_node("Health"):
				body.get_node("Health").take_damage(int(damage_per_second * tick_interval), caster)
				var thermal = AbilityBase.find_passive(caster)
				if thermal and thermal.has_method("mark_vulnerable"):
					thermal.mark_vulnerable(body)
	if is_instance_valid(segment):
		segment.queue_free()
