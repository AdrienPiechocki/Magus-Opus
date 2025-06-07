extends CharacterBody3D
class_name Player

@onready var NameTag:Label3D = $NameTag
@onready var Inputs:Node = $Inputs
@onready var Camera:Camera3D = $Camera3D
@onready var Lantern:OmniLight3D = $Lantern
@onready var Sprite:MeshInstance3D = $Sprite
@onready var Menu:Panel = $Camera3D/UI/Menu
@onready var Hands:CanvasLayer = $Camera3D/UI/Hands
@onready var HUD:CanvasLayer = $Camera3D/UI/HUD

@export var lantern_lit:bool
@export var in_menu:bool

var is_name_set:bool

var light_level:float

var last_known_pos:Array = []
var delay:float = 0.0
var deadzone:Vector3 = Vector3(50, -10, 50)
var spawn:Vector3
var recent_calls:Array = []

var data:Dictionary = {}

func _enter_tree() -> void:
	if GameManager.players[1]["solo"]:
		get_node("MultiplayerSynchronizer").free()
	else:
		set_multiplayer_authority(int(name))
		
func _ready() -> void:
	GameManager.player_joined_in_game.connect(sync)
	if GameManager.players[1]["solo"]:
		Camera.current = true
	else:
		Camera.current = is_multiplayer_authority()
	Sprite.hide()
	Hands.show()
	HUD.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	last_known_pos.append(position)
	spawn = position
	
	
func _process(_delta: float) -> void:
	#Set player nametag and other players visibility:
	if not GameManager.get_player_list().is_empty() and not is_name_set:
		is_name_set = true
		
	if is_multiplayer_authority():
		Menu.visible = in_menu
		HUD.visible = !in_menu
	
	for player in get_tree().get_nodes_in_group("Player"):
		if player.name != name:
			set_player_name.rpc_id(int(player.name))
			set_visibility.rpc_id(int(player.name))
	
@rpc("any_peer", "call_local")
func set_player_name():
	if int(name) in GameManager.players:
		NameTag.text = str(GameManager.players[int(name)]["name"])

@rpc("any_peer", "call_local")
func set_visibility():
	Sprite.show()
	Hands.hide()
	HUD.hide()

@rpc("any_peer", "unreliable")
func _update(new_position: Vector3, new_rotation_degrees: Vector3, new_lantern_lit:bool ,new_in_menu:bool):
	if not is_multiplayer_authority():
		position = new_position
		rotation_degrees = new_rotation_degrees
		lantern_lit = new_lantern_lit
		in_menu = new_in_menu

func _physics_process(delta: float) -> void:	
	if int(name) in GameManager.players and GameManager.players[int(name)]["in_game"]:
		if not GameManager.players[int(name)]["solo"] and (multiplayer.multiplayer_peer == null or is_multiplayer_authority()):
			_update.rpc(position, rotation_degrees, lantern_lit, in_menu)
		
		#data synchronization:
		if should_sync():
			sync.rpc()
		if delay <= 0.5:
			delay += delta

		if out_of_bounds():
			position = position_backup()
			
		if !in_menu:
			#handle movement
			velocity = Inputs.motion * Inputs.speed
			velocity.y = Inputs.motion.y * Inputs.base_speed
			move_and_slide()
	
func should_sync() -> bool:
	if Input.is_anything_pressed():
		return true
	return false

@rpc("any_peer", "call_local")
func sync():
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
