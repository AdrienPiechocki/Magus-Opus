extends CharacterBody3D

var speed:float
@export var synced_position:Vector3
var lantern_lit:bool
var in_menu:bool

@onready var label:Label3D = $NameTag
@onready var inputs:Node = $Inputs
@onready var camera:Camera3D = $Camera3D
@onready var head:Node3D = $Head
@onready var lantern:OmniLight3D = $Head/Lantern
@onready var sprite:MeshInstance3D = $Sprite
@onready var hands:CanvasLayer = $Hands
@onready var left_hand:TextureRect = $Hands/LeftHand
@onready var right_hand:TextureRect = $Hands/RightHand
@onready var UI:Control = $UserInterface

var is_name_set:bool

var bob_time:float = 0.0
var idle_bob_speed:float = 3
var idle_bob_amount:float = 0.02
var flicker_amount:float = 0.2

var last_known_pos:Array = []
var delay:float = 0.0

var data:Dictionary = {}

var deadzone:Vector3 = Vector3(50, -10, 50)
var spawn:Vector3
var recent_calls:Array = []

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

func _ready() -> void:
	camera.current = is_multiplayer_authority()
	sprite.hide()
	hands.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	last_known_pos.append(position)
	if is_multiplayer_authority():
		for _data in GameManager.players[int(name)]["data"]:
			set(str(_data), GameManager.players[int(name)]["data"][_data])
	synced_position = position
	spawn = position
	
func _process(_delta: float) -> void:
	#Set player nametag and other players visibility:
	if not GameManager.get_player_list().is_empty() and not is_name_set:
		is_name_set = true
		for player in get_tree().get_nodes_in_group("Player"):
			if player.name != name:
				set_player_name.rpc_id(int(player.name))
				set_visibility.rpc_id(int(player.name))

	
@rpc("any_peer", "call_local")
func toggle_lantern():
	lantern_lit = !lantern_lit

@rpc("any_peer", "call_local")
func set_lantern(delta:float):	
	if lantern_lit and lantern.light_energy >= 1:
		flicker_amount += delta * 5
		lantern.omni_range += sin(flicker_amount) * 0.002
	if lantern_lit and lantern.light_energy < 1:
		lantern.light_energy += delta
	if !lantern_lit and lantern.light_energy > 0:
		lantern.light_energy -= delta

@rpc("any_peer", "call_local")
func set_player_name():
	label.text = str(GameManager.players[int(name)]["name"])

@rpc("any_peer", "call_local")
func set_visibility():
	sprite.show()
	hands.hide()

func _physics_process(delta: float) -> void:	
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
			# The client which this player represent will update the controls state, and notify it to everyone.
			inputs.update(delta)
			camera_bob(delta)
			#Manage lantern
			if Input.is_action_just_pressed("light"):
				toggle_lantern.rpc()
			set_lantern.rpc(delta)
			
			#Escape Menu:
			UI.visible = in_menu
			toggle_mouse()
			if Input.is_action_just_pressed("menu"):
				in_menu = !in_menu
		
		#data synchronization:
		if should_sync():
			data = {"position": position, 
				"rotation": rotation, 
				"lantern_lit": lantern_lit,
				"in_menu": in_menu
				}
			GameManager.players[int(name)]["data"] = data
		#backup last known positions
			if delay >= 0.5:
				delay = 0.0
				backup_position(3)
		if delay <= 0.5:
			delay += delta
			
		if is_multiplayer_authority():
			synced_position = position
		else:
			position = synced_position
		
		if out_of_bounds():
			position = position_backup()
			
		if !in_menu:
			#handle sprint / player speed
			speed = (14 if Input.is_action_pressed("sprint") and is_on_floor() else 7)
			
			#handle movement
			velocity = inputs.motion * speed
			
			move_and_slide()

func should_sync() -> bool:
	if Input.is_anything_pressed():
		return true
	return false

func backup_position(size:int):
	last_known_pos.append(position)
	if last_known_pos.size() > size:
		last_known_pos.remove_at(0)

func out_of_bounds() -> bool:
	if position.y < deadzone.y:
		return true
	elif position.x < -deadzone.x or position.x > deadzone.x:
		return true
	elif position.z < -deadzone.z or position.z > deadzone.z:
		return true
	else:
		return false

func called_recently(interval:float, maximum:int) -> bool:
	var now = Time.get_ticks_msec() / 1000.0  # secondes
	recent_calls.append(now)
	recent_calls = recent_calls.filter(func(t):
		return now - t <= interval
	)
	return recent_calls.size() > maximum

func position_backup() -> Vector3:
	var list = last_known_pos
	list.reverse()
	if called_recently(0.5, 2):
		return spawn
	for pos in list:
		if pos.x < deadzone.x and pos.x > -deadzone.x:
			if pos.y > deadzone.y:
				if pos.z < deadzone.z and pos.z > -deadzone.z:
					return pos
	return spawn

func toggle_mouse():
	if in_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func camera_bob(delta:float):
	if !in_menu and velocity.length() > 0 and is_on_floor():
		bob_time += delta * (22 if Input.is_action_pressed("sprint") else 12)
		camera.position.y = 0.66 + sin(bob_time) * (0.08 if Input.is_action_pressed("sprint") else 0.06)
		hands.offset.y = -sin(bob_time) * (8 if Input.is_action_pressed("sprint") else 6)
	else:
		bob_time += delta * idle_bob_speed
		camera.position.y = 0.66 + sin(bob_time) * idle_bob_amount
		hands.offset.y = -sin(bob_time) * idle_bob_amount * 100
