extends Node

signal impact_detected(strength: float, collider: Node3D)

@onready var car: VehicleBody3D = get_parent()

var previous_velocity: Vector3
var impact_speed_before: float = 0.0
var impact_speed_after: float = 0.0
var impact_position: Vector3 = Vector3.ZERO
var impact_time: float = 0.0

func _ready():
	previous_velocity = car.linear_velocity
