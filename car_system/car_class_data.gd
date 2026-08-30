extends Resource
class_name CarClassData

## One resource per CLASS (Nitro, Bastion, Engineer, Havoc, All-Rounder).
## Create these in the editor: right-click in the FileSystem dock ->
## New Resource -> CarClassData, then fill in the fields in the Inspector.
## Save each as e.g. res://data/classes/nitro.tres

@export var car_class_id: String = ""     # "NITRO" - must match whatever
										   # CarController.car_class_name
										   # checks (e.g. Engineer's
										   # "no copying another Engineer" rule)
@export var display_name: String = ""      # "Nitro"

@export_group("Ability Scripts")
@export var passive_script: Script
@export var ability1_script: Script
@export var ability2_script: Script
@export var ultimate_script: Script

@export_group("Base Stats")
@export var base_mass: float = 900.0
@export var base_max_torque: float = 4000.0
@export var base_max_rpm: float = 1200.0
@export var base_max_steering: float = 0.5

@export_group("Subclasses")
@export var subclasses: Array[CarSubclassData] = []
