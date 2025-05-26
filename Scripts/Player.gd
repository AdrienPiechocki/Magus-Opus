extends CharacterBody3D

var speed:float = 6.0

@export var synced_position := Vector3()

@onready var label = $Label3D
@onready var inputs = $Inputs

var flag:bool = true
var jumping:bool = false

func _ready() -> void:
	position = synced_position
	if str(name).is_valid_int():
		get_node("Inputs/InputSynchronizer").set_multiplayer_authority(str(name).to_int())
	$head/Camera3D.current = get_node("Inputs/InputSynchronizer").is_multiplayer_authority()

func _process(_delta: float) -> void:
	if not GameManager.get_player_list().is_empty() and flag:
		flag = false
		for player in get_tree().get_nodes_in_group("Player"):
			if player.name != name:
				set_player_name.rpc_id(int(player.name))

@rpc("any_peer", "call_local")
func set_player_name():
	label.text = str(GameManager.players[int(name)])

func _physics_process(delta: float) -> void:	
	#gravity = calcGravity()
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(delta)
			
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
	
	#handle movement
	velocity = inputs.motion * speed

	#handle sprint / player speed
	if Input.is_action_pressed("sprint") and is_on_floor():
		speed = 10
	elif Input.is_action_just_released("sprint"):
		speed = 6
		
	move_and_slide()
