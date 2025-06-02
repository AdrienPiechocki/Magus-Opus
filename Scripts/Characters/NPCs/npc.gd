extends CharacterBody3D

@export_range(-180, 180) var orientation:float

func _physics_process(_delta: float) -> void:
	rotation_degrees.y = orientation
