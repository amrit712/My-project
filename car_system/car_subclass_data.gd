extends Resource
class_name CarSubclassData

## One resource per visual VARIANT within a class (e.g. Nitro -> F1,
## Camaro, Chiron). Create in the editor: right-click in FileSystem ->
## New Resource -> CarSubclassData, fill in the Inspector, save as e.g.
## res://car_system/subclasses/nitro_chiron.tres

@export var subclass_id: String = ""      # "CHIRON"
@export var display_name: String = ""      # "Chiron"
@export var body_scene: PackedScene        # the visual mesh scene for this variant

@export_group("Stat Multipliers")
@export var mass_multiplier: float = 1.0
@export var torque_multiplier: float = 1.0
@export var top_speed_multiplier: float = 1.0
@export var steering_multiplier: float = 1.0

@export_group("Body Centering")
## If a model's own origin/pivot isn't centered on the chassis, the body
## mesh spawns offset instead of sitting where it should. Auto-detection
## (default) fixes X/Z horizontal centering from mesh geometry - turn
## override on and type a full value if a model has extra geometry that
## throws auto-detection off entirely.
@export var override_body_position: bool = false
@export var body_position_offset: Vector3 = Vector3.ZERO
## Applied ON TOP of whichever X/Z method above is used (auto or
## override) - use this alone to nudge ride height up/down without
## needing to also know/replicate the auto-detected X/Z values.
@export var body_vertical_offset: float = 0.0

@export_group("Wheel Position Offsets")

## If enabled, the automatically detected wheel positions are preserved
## and these offsets are applied on top of them.
##
## These values are LOCAL to the car chassis.
##
## Vector3.ZERO = no correction.
@export var wheel_position_offsets_enabled: bool = false

@export var back_left_wheel_offset: Vector3 = Vector3.ZERO
@export var back_right_wheel_offset: Vector3 = Vector3.ZERO
@export var front_left_wheel_offset: Vector3 = Vector3.ZERO
@export var front_right_wheel_offset: Vector3 = Vector3.ZERO

@export_group("Model Orientation Correction")
## Not every model is exported with the same forward/up axis convention
## (F1 happened to match by luck - Chiron doesn't). Instead of re-exporting
## the model, tune these degree values in the Inspector until the body/
## wheels look right - CarSpawner and WheelAttacher apply them
## automatically. Leave at (0,0,0) for models that already work correctly.
@export var body_rotation_correction: Vector3 = Vector3.ZERO   # degrees
@export var wheel_rotation_correction: Vector3 = Vector3.ZERO  # degrees
