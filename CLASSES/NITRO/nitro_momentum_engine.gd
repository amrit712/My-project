extends PassiveBase
class_name NitroMomentumEngine

# Passive - Momentum Engine
# Above 80% top speed: +20% mana regen.
# Sustained drifting builds Drift Charge; at max charge, the NEXT ability
# used gets -20% cooldown, and charge is consumed.
#
# Wiring note: this doesn't auto-apply the cooldown discount to whichever
# ability you press next, since it has no way of knowing which one that'll
# be. In your input-handling code, do this right before calling try_activate:
#
#   if momentum_engine.is_drift_charged():
#       some_ability.pending_cooldown_multiplier = 1.0 - momentum_engine.consume_charge()
#   some_ability.try_activate(self)

@export var speed_threshold_ratio: float = 0.8
@export var max_reference_speed: float = 30.0  # m/s treated as "100% speed"
@export var mana_regen_bonus: float = 0.20
@export var drift_slip_threshold: float = 0.35  # 0 = pure forward, 1 = pure sideways
@export var drift_charge_rate: float = 25.0     # charge/sec while drifting
@export var drift_charge_max: float = 100.0
@export var cooldown_reduction_on_max_charge: float = 0.20

var drift_charge: float = 0.0
var _base_mana_regen: float = -1.0

func on_process(delta: float, caster: Node, _power_scale: float = 1.0):
	if not caster.has_node("Mana"):
		return
	var mana_node = caster.get_node("Mana")

	if _base_mana_regen < 0.0:
		_base_mana_regen = mana_node.regen_rate

	var speed = caster.linear_velocity.length()
	var above_threshold = speed > max_reference_speed * speed_threshold_ratio
	mana_node.regen_rate = _base_mana_regen * (1.0 + mana_regen_bonus) if above_threshold else _base_mana_regen

	if _get_slip_amount(caster) > drift_slip_threshold and speed > 3.0:
		drift_charge = min(drift_charge_max, drift_charge + drift_charge_rate * delta)

func _get_slip_amount(caster: Node) -> float:
	var vel = caster.linear_velocity
	if vel.length() < 0.5:
		return 0.0
	var forward = -caster.global_transform.basis.z
	return 1.0 - abs(forward.dot(vel.normalized()))

func is_drift_charged() -> bool:
	return drift_charge >= drift_charge_max

func consume_charge() -> float:
	if is_drift_charged():
		drift_charge = 0.0
		return cooldown_reduction_on_max_charge
	return 0.0
