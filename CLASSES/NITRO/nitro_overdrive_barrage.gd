extends AbilityBase
class_name NitroOverdriveBarrage

# Ultimate - Overdrive Barrage
# For 7s: infinite boost, +35% top speed. Passing within 5m of an enemy
# marks them Vulnerable (your team deals +15% damage to them for 4s).
# An enemy can only be re-marked once every 2s, so Nitro can't just farm
# the same target on repeat for a permanent debuff.

@export var duration: float = 7.0
@export var top_speed_bonus: float = 0.35
@export var mark_radius: float = 5.0
@export var vulnerable_duration: float = 4.0
@export var vulnerable_team_damage_bonus: float = 0.15
@export var mark_recheck_interval: float = 2.0

func _init():
	slot = Slot.ULTIMATE
	cooldown = 60.0
	mana_cost = 100.0

var is_active: bool = false
var _timer: float = 0.0
var _mark_cooldowns: Dictionary = {}  # car instance id -> seconds until remarkable

func activate(caster):
	is_active = true
	_timer = duration
	_mark_cooldowns.clear()
	if caster.has_node("StatusEffects"):
		# Magnitude here doubles as the top-speed bonus your CarController's
		# throttle code should read: e.g.
		#   final_force *= 1.0 + status_effects.get_magnitude("overdrive_barrage")
		caster.get_node("StatusEffects").apply_status("overdrive_barrage", duration, top_speed_bonus)
	print(caster.name, " unleashes Overdrive Barrage")

func _physics_process(delta):
	if !is_active:
		return
	var caster = get_parent()
	_timer -= delta

	for key in _mark_cooldowns.keys():
		_mark_cooldowns[key] -= delta
		if _mark_cooldowns[key] <= 0.0:
			_mark_cooldowns.erase(key)

	for car in get_nearby_cars(caster, mark_radius, false):
		var id = car.get_instance_id()
		if _mark_cooldowns.has(id):
			continue
		_mark_cooldowns[id] = mark_recheck_interval
		if car.has_node("StatusEffects"):
			car.get_node("StatusEffects").apply_status(
				"vulnerable", vulnerable_duration, vulnerable_team_damage_bonus, true
			)
		print(caster.name, " marks ", car.name, " Vulnerable")

	if _timer <= 0.0:
		is_active = false
		print(caster.name, "'s Overdrive Barrage ends")
