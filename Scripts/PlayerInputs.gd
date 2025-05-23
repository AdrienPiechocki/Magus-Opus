extends Node

@export
var motion = Vector3()

@onready var camera = $"../head/Camera3D"
@onready var head = $"../head"
var mouse_sensivity:float = 0.02

func update():
	
	var m = Input.get_vector("left", "right", "forward", "backward")
	var movement_dir = get_parent().get_node("head").basis * Vector3(m.x, 0, m.y)

	motion = movement_dir

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && camera.current:
		head.rotate_y(-event.relative.x * mouse_sensivity)
		camera.rotate_x(-event.relative.y * mouse_sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
