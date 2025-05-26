extends CharacterBody3D

@onready var head = $head

@export_range(-180, 180) var orientation:float
var spin:float = 0

func _physics_process(delta: float) -> void:
	spin += 100 * delta
	if spin > 180:
		spin = -180
	head.rotation_degrees.y = orientation
