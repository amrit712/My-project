extends Node

var classes: Array[CarClassData] = [
	preload("res://CLASSES/NITRO/nitro.tres")
]

func get_class_data(class_id: String) -> CarClassData:
	for c in classes:
		if c.car_class_id == class_id:
			return c

	push_warning("CarRegistry: no class found for id '%s'" % class_id)
	return null


func get_subclass_data(class_id: String, subclass_id: String) -> CarSubclassData:
	var class_data = get_class_data(class_id)

	if class_data == null:
		return null

	for s in class_data.subclasses:
		if s.subclass_id == subclass_id:
			return s

	push_warning(
		"CarRegistry: no subclass '%s' under class '%s'"
		% [subclass_id, class_id]
	)

	return null


func get_all_class_ids() -> Array:
	var ids := []

	for c in classes:
		ids.append(c.car_class_id)

	return ids


func get_subclass_ids(class_id: String) -> Array:
	var class_data = get_class_data(class_id)

	if class_data == null:
		return []

	var ids := []

	for s in class_data.subclasses:
		ids.append(s.subclass_id)

	return ids
