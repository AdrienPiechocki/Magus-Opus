extends Node

@export var motion:Vector3 = Vector3.ZERO
var cooldown:float = 0.5

@onready var camera = $"../Head/Camera3D"
@onready var head = $"../Head"

var mouse_sensivity:float = 0.02
var movement_dir:Vector3

func update(delta: float):

	#handle horizontal movement
	var m = Input.get_vector("left", "right", "forward", "backward")
	movement_dir.x = m.x
	movement_dir.z = m.y
	
	#handle gravity
	if not get_parent().is_on_floor():
		movement_dir.y -= 10 * delta
	
	#handle jump
	if Input.is_action_pressed("jump") and get_parent().is_on_floor() and cooldown <= 0:
		cooldown = 0.5
		movement_dir.y = (1.9 if Input.is_action_pressed("sprint") else 2.0)
	#jump cooldown
	if cooldown > 0:
		cooldown -= delta
	
	#movment based on camera orientation
	movement_dir = head.basis * movement_dir
	
	motion = movement_dir
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && camera.current:
		rotate_head.rpc(event)
		camera.rotate_x(-event.relative.y * mouse_sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

@rpc("any_peer", "call_local")
func rotate_head(event:InputEvent):
	head.rotate_y(-event.relative.x * mouse_sensivity)
