extends AbilityBase
class_name AllRounderApexMode

# Ultimate - Apex Mode
# For 10s: +20% acceleration, +15% top speed, +20% collision damage
# (integration needed in CarController/CollisionManager - see notes), and
# +20% ability recharge (this last part is handled automatically by
# AbilityBase.try_activate checking for the "apex_mode" status).
# Every ability use while active refreshes 25% of the OTHER abilities'
# remaining cooldowns - the payoff for Fluid Driver's chaining passive.

@export var duration: float = 10.0
@export var acceleration_bonus: float = 0.20
@export var top_speed_bonus: float = 0.15
@export var collision_damage_bonus: float = 0.20

func _init():
	slot = Slot.ULTIMATE
	cooldown = 60.0
	mana_cost = 100.0

var is_active: bool = false
var _timer: float = 0.0

func activate(caster):
	var fluid_driver = AbilityBase.find_passive(caster)
	if fluid_driver and fluid_driver.has_method("on_ability_used"):
		fluid_driver.on_ability_used(caster, slot)

	is_active = true
	_timer = duration
	if caster.has_node("StatusEffects"):
		# Magnitude carries the top-speed/accel bonus so CarController can
		# read it directly, e.g.:
		#   var apex_bonus = status_effects.get_magnitude("apex_mode")
		#   final_force *= 1.0 + apex_bonus
		caster.get_node("StatusEffects").apply_status("apex_mode", duration, acceleration_bonus)
	print(caster.name, " enters Apex Mode")

func _process(delta):
	super._process(delta)
	if is_active:
		_timer -= delta
		if _timer <= 0.0:
			is_active = false
			print(get_parent().name, "'s Apex Mode ends")

# Called automatically by AbilityBase.try_activate() whenever ANY ability
# on this caster fires while Apex Mode is active.
func on_any_ability_used(caster: Node, used_slot: int):
	if !is_active:
		return
	for child in caster.get_children():
		if child is AbilityBase and child.slot != used_slot:
			child._cooldown_timer = max(0.0, child._cooldown_timer * 0.75)
