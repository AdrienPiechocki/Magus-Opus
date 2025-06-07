extends Node

enum State {
	STATE_WALKING,
	STATE_LEANING,
	STATE_CROUCHING,
	STATE_CRAWLING,
}
var state = State.STATE_WALKING

@export_range(-45.0, -8.0, 1.0) var max_lean
var camera_starting_pos:Vector3
var speed:float
@export var base_speed:float = 7
@export var slow_speed:float = 3.5
@export var fast_speed:float = 14
var max_fall_speed = -3
var mouse_sensivity:float = 0.02
var movement_dir:Vector3
var flicker_amount:float = 0.2
var bob_time:float = 0.0
var idle_bob_speed:float = 12
var idle_bob_amount:float = 0.02
var camera_pos_y:float = 0.66

@export var motion:Vector3 = Vector3.ZERO

@onready var _player:Player = $".."
@onready var Camera:Camera3D = $"../Camera3D"
@onready var Lantern:OmniLight3D = $"../Lantern"
@onready var Menu:Panel = $"../Camera3D/UI/Menu"
@onready var HUD:CanvasLayer = $"../Camera3D/UI/HUD"
@onready var Sprite:MeshInstance3D = $"../Sprite"
@onready var Hands:CanvasLayer = $"../Camera3D/UI/Hands"
@onready var Left_hand:TextureRect = $"../Camera3D/UI/Hands/LeftHand"
@onready var Right_hand:TextureRect = $"../Camera3D/UI/Hands/RightHand"
@onready var Hitbox:CollisionShape3D = $"../Hitbox"

func _ready() -> void:
	camera_starting_pos = Camera.position
	Hitbox.shape = Hitbox.shape.duplicate()
	
func _physics_process(delta: float) -> void:
	movement(delta)
	camera_bob(delta)
	if (1 in GameManager.players.keys() and GameManager.players[1]["solo"]) or is_multiplayer_authority():
		toggle_mouse()
	
	#ANY STATE ACTIONS:
	#Manage Lantern:
	if Input.is_action_just_pressed("light"):
		toggle_Lantern()
	set_Lantern(delta)
	#Toggle Menu:
	if Input.is_action_just_pressed("menu"):
		toggle_menu()
	
	
	#SPECIFIC STATE ACTIONS:
	match state:
			State.STATE_WALKING:
				speed = base_speed
				if _player.velocity.length() > 0:
					idle_bob_speed = 12
					idle_bob_amount = 0.04
				else:
					idle_bob_speed = 6
					idle_bob_amount = 0.02
				if camera_pos_y < camera_starting_pos.y-idle_bob_amount:
					camera_pos_y += delta * 3
					
				set_collision_height(2.0)
				
				if Input.is_action_pressed("lean_left") or Input.is_action_pressed("lean_right"):
					state = State.STATE_LEANING
					return
				
				if Input.is_action_pressed("crouch"):
					state = State.STATE_CROUCHING
					return
				
				if Input.is_action_pressed("crawl"):
					state = State.STATE_CRAWLING
					return
					
				if Input.is_action_pressed("sneak"):
					speed = slow_speed
					if _player.velocity.length() > 0:
						idle_bob_speed = 6
						idle_bob_amount = 0.02
					
				if Input.is_action_pressed("sprint"):
					speed = fast_speed
					if _player.velocity.length() > 0:
						idle_bob_speed = 22
						idle_bob_amount = 0.08
				
			State.STATE_LEANING:
				lean()
			
			State.STATE_CROUCHING:
				crouch()
			
			State.STATE_CRAWLING:
				crawl(delta)
			


func movement(delta: float):
	
	#handle horizontal movement
	var m = Input.get_vector("left", "right", "forward", "backward")
	movement_dir.x = m.x
	movement_dir.z = m.y
	
	#handle gravity
	if not get_parent().is_on_floor():
		movement_dir.y -= 10 * delta
		movement_dir.y = max(movement_dir.y, max_fall_speed)
	#handle jump
	elif Input.is_action_pressed("jump"):
		movement_dir.y = 1.5
	else:
		movement_dir.y = 0

	#movment based on player orientation
	movement_dir = get_parent().basis * movement_dir
	
	motion = movement_dir
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Camera.current and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		get_parent().rotate_y(-event.relative.x * mouse_sensivity)
		Camera.rotation.x += -event.relative.y * mouse_sensivity
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func lean():
	var axis = (Input.get_action_strength("lean_right") - Input.get_action_strength("lean_left"))
	var from = Camera.position
	var to = camera_starting_pos + (Camera.global_transform.basis.x * 0.2 * axis)
	Camera.position = lerp(from, to, 0.1)
	from = Camera.rotation_degrees.z
	to = max_lean * axis
	Camera.rotation_degrees.z = lerp(from, to, 0.1)
	
	speed = 4
	
	var diff = Camera.position - camera_starting_pos
	if axis == 0 and diff.length() <= 0.01:
		state = State.STATE_WALKING
		return

func crouch():
	speed = slow_speed
	set_collision_height(1.5)
	if Input.is_action_just_released("crouch"):
		state = State.STATE_WALKING
		return

func crawl(delta:float):
	if camera_pos_y > 0:
		camera_pos_y -= delta * 2
	speed = slow_speed - 2
	set_collision_height(1.0)
	if Input.is_action_just_released("crawl"):
		state = State.STATE_WALKING
		return

func toggle_mouse():
	if _player.in_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func toggle_Lantern():
	_player.lantern_lit = !_player.lantern_lit

func set_Lantern(delta:float):
	await get_tree().process_frame
	if _player.lantern_lit and Lantern.light_energy >= 1:
		flicker_amount += delta * 5
		Lantern.omni_range += sin(flicker_amount) * 0.002
	if _player.lantern_lit and Lantern.light_energy < 1:
		Lantern.light_energy += delta
	if !_player.lantern_lit and Lantern.light_energy > 0:
		Lantern.light_energy -= delta
	if Lantern.light_energy < 0:
		Lantern.light_energy = 0

func toggle_menu():
	_player.in_menu = !_player.in_menu

func camera_bob(delta:float):
	bob_time += delta * idle_bob_speed
	Camera.position.y = camera_pos_y + sin(bob_time) * idle_bob_amount
	Hands.offset.y = -sin(bob_time/2) * idle_bob_amount * 100

func set_collision_height(val:float):
	if (1 in GameManager.players.keys() and GameManager.players[1]["solo"]) or is_multiplayer_authority():
		Hitbox.shape.height = val
