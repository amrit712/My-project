extends AbilityBase
class_name BastionDeployableBunker

# Ability 1 - Deployable Bunker
# Bastion stops, anchors, and deploys a frontal shield for up to 5s. The
# shield absorbs incoming ability damage. Bastion cannot drive while
# deployed. Press again to retract early.
#
# Integration notes:
# - Your CarController needs to check a flag (here: `engine_locked`) and
#   zero engine_force while it's true. Simplest: in _physics_process,
#   `if engine_locked: return` right after the destroyed check, or skip
#   the throttle block.
# - "Allies pass through, enemies cannot" needs per-team collision layers,
#   which aren't set up in the current codebase - flagged as a TODO below.

@export var max_duration: float = 5.0
@export var shield_forward_offset: float = 2.5

func _init():
	slot = Slot.ABILITY_1
	cooldown = 18.0
	mana_cost = 20

var is_deployed: bool = false
var _deploy_timer: float = 0.0
var _shield_body: StaticBody3D = null

func activate(caster):
	if is_deployed:
		retract(caster)
		return
	is_deployed = true
	_deploy_timer = max_duration
	caster.set("engine_locked", true)
	_spawn_shield(caster)
	print(caster.name, " deploys Bunker Shield")

func retract(caster):
	is_deployed = false
	_deploy_timer = 0.0
	caster.set("engine_locked", false)
	if is_instance_valid(_shield_body):
		_shield_body.queue_free()
	_shield_body = null
	print(caster.name, " retracts Bunker Shield")

func _process(delta):
	super._process(delta)
	if is_deployed:
		_deploy_timer -= delta
		if _deploy_timer <= 0.0:
			retract(get_parent())

func _spawn_shield(caster):
	var shield := StaticBody3D.new()
	shield.name = "BunkerShield"

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.0, 1.5, 0.3)
	mesh.mesh = box
	shield.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape.shape = box_shape
	shield.add_child(shape)

	caster.get_tree().current_scene.add_child(shield)
	var forward = -caster.global_transform.basis.z
	shield.global_transform.origin = caster.global_position + forward * shield_forward_offset
	shield.global_transform.basis = caster.global_transform.basis

	_shield_body = shield
	# TODO: put the shield on its own physics layer, and set each car's
	# collision mask to include it only if they're an enemy of `caster` -
	# needs a team system (team_id export on CarController) to do properly.

# Call from wherever ability damage would be applied to Bastion, before
# actually applying it: `amount = bunker.try_absorb(amount)`.
func try_absorb(amount: int) -> int:
	if is_deployed:
		print("Bunker Shield absorbed ", amount, " damage")
		return 0
	return amount
