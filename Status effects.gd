extends Node
class_name StatusEffects

# Generic timed status-effect tracker. Every ability in this kit reads/writes
# through this instead of inventing its own bespoke flags, so effects compose
# instead of colliding (e.g. Havoc's slow + Engineer's slow don't need to
# know about each other).
#
# Attach this as a child node named "StatusEffects" on every car, alongside
# Health and Mana. Abilities check `car.has_node("StatusEffects")` before
# touching it, so it's safe even on cars that don't have it yet.

signal status_applied(effect_name: String, magnitude: float, duration: float)
signal status_expired(effect_name: String)

# effect_name -> { "time_left": float, "magnitude": float }
var effects: Dictionary = {}

func _process(delta):
	var expired: Array = []
	for effect_name in effects.keys():
		effects[effect_name]["time_left"] -= delta
		if effects[effect_name]["time_left"] <= 0.0:
			expired.append(effect_name)
	for effect_name in expired:
		effects.erase(effect_name)
		status_expired.emit(effect_name)

# refresh_only_if_stronger: if true, an existing effect is only overwritten
# when the new one is both stronger AND longer - stops a weak re-application
# from cutting a strong one short.
func apply_status(effect_name: String, duration: float, magnitude: float = 1.0, refresh_only_if_stronger: bool = false):
	if refresh_only_if_stronger and effects.has(effect_name):
		var existing = effects[effect_name]
		if existing["magnitude"] >= magnitude and existing["time_left"] >= duration:
			return
	effects[effect_name] = {"time_left": duration, "magnitude": magnitude}
	status_applied.emit(effect_name, magnitude, duration)

func has_status(effect_name: String) -> bool:
	return effects.has(effect_name)

func get_magnitude(effect_name: String) -> float:
	if effects.has(effect_name):
		return effects[effect_name]["magnitude"]
	return 0.0

func get_time_left(effect_name: String) -> float:
	if effects.has(effect_name):
		return effects[effect_name]["time_left"]
	return 0.0

func clear_status(effect_name: String):
	if effects.has(effect_name):
		effects.erase(effect_name)
		status_expired.emit(effect_name)

# Cleanse everything EXCEPT the names passed in `keep` - useful for a
# "cleanse" ability that shouldn't strip its own buffs.
func clear_all(keep: Array = []):
	for effect_name in effects.keys():
		if effect_name in keep:
			continue
		effects.erase(effect_name)
		status_expired.emit(effect_name)
