extends CharacterBody3D

var speed:float

@export var synced_position := Vector3()

@onready var label = $NameTag
@onready var inputs = $Inputs
@onready var camera = $Head/Camera3D
@onready var head = $Head
@onready var lantern = $Head/Lantern
@onready var sprite = $Sprite
@onready var hands = $Hands
@onready var left_hand = $Hands/LeftHand
@onready var right_hand = $Hands/RightHand

var lantern_lit:bool = false
var is_name_set:bool = false

var bob_time:float = 0.0
var idle_bob_speed:float = 3
var idle_bob_amount:float = 0.02
var flicker_amount:float = 0.2

func _ready() -> void:
	position = synced_position
	if str(name).is_valid_int():
		get_node("Inputs/InputSynchronizer").set_multiplayer_authority(str(name).to_int())
	camera.current = get_node("Inputs/InputSynchronizer").is_multiplayer_authority()
	sprite.hide()
	
func _process(_delta: float) -> void:
	#Set player nametag:
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
	label.text = str(GameManager.players[int(name)])

@rpc("any_peer", "call_local")
func set_visibility():
	sprite.show()

func _physics_process(delta: float) -> void:	
	#gravity = calcGravity()
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(delta)
		camera_bob(delta)
		#Manage lantern
		if Input.is_action_just_pressed("light"):
			toggle_lantern.rpc()
		set_lantern.rpc(delta)
		
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
		
	#handle sprint / player speed
	speed = (14 if Input.is_action_pressed("sprint") and is_on_floor() else 7)

	#handle movement
	velocity = inputs.motion * speed
	
	move_and_slide()


func camera_bob(delta:float):
	if velocity.length() > 0:
		bob_time += delta * (22 if Input.is_action_pressed("sprint") else 12)
		camera.position.y = sin(bob_time) * (0.08 if Input.is_action_pressed("sprint") else 0.06)
		hands.offset.y = -sin(bob_time) * (8 if Input.is_action_pressed("sprint") else 6)
	else:
		bob_time += delta * idle_bob_speed
		camera.position.y = sin(bob_time) * idle_bob_amount
		hands.offset.y = -sin(bob_time) * idle_bob_amount * 100
