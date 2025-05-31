extends Node

@export var motion:Vector3 = Vector3.ZERO

@onready var camera = $"../Camera3D"
@onready var head = $"../Head"

var mouse_sensivity:float = 0.02
var movement_dir:Vector3
var rotating_head:bool = false

func update(delta: float):
	
	#handle horizontal movement
	var m = Input.get_vector("left", "right", "forward", "backward")
	movement_dir.x = m.x
	movement_dir.z = m.y
	
	#handle gravity
	if not get_parent().is_on_floor():
		movement_dir.y -= 10 * delta
	#handle jump
	elif Input.is_action_pressed("jump"):
		movement_dir.y = 2
	
	#movment based on player orientation
	movement_dir = get_parent().basis * movement_dir
	
	motion = movement_dir
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and camera.current and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotating_head = true
		get_parent().rotate_y(-event.relative.x * mouse_sensivity)
		head.rotate_y(-event.relative.x * mouse_sensivity)
		camera.rotate_x(-event.relative.y * mouse_sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	else:
		rotating_head = false
