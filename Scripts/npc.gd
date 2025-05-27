extends CharacterBody3D

@onready var head = $head

@export_range(-180, 180) var orientation:float

func _physics_process(_delta: float) -> void:
	head.rotation_degrees.y = orientation
