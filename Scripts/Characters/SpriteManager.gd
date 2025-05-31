extends MeshInstance3D

var mat:StandardMaterial3D
var angle:float
var pos:Vector3

@export var North:Texture
@export var NorthEast:Texture
@export var East:Texture
@export var SouthEast:Texture
@export var South:Texture
@export var SouthWest:Texture
@export var West:Texture
@export var NorthWest:Texture

@onready var sideToMaterial:Array = [
	NorthWest,
	North,
	NorthEast,
	East,
	SouthEast,
	South,
	SouthWest,
	West
]

var currentSide:int

@onready var head = $"../Head"

func _ready() -> void:
	multiplayer.allow_object_decoding = true
	mat = mesh.surface_get_material(0).duplicate()
	
func _physics_process(_delta: float) -> void:
	if everyone_in_game() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		update.rpc_id(int(get_parent().name))
		for player in get_tree().get_nodes_in_group("Player"):
			if player.name != get_parent().name:
				pos = player.position.direction_to(global_position)
				if abs(pos.x) < 0.5:
					if pos.z > 0:
						set_texture(player, [West, SouthWest, South, SouthEast, East, NorthEast, North, NorthWest])
					elif pos.z < 0:
						set_texture(player, [East, NorthEast, North, NorthWest, West, SouthWest, South, SouthEast])
				elif pos.x > 0:
					if abs(pos.z) < 0.5:
						set_texture(player, [South, SouthEast, East, NorthEast, North, NorthWest, West, SouthWest])
					elif pos.z > 0:
						set_texture(player, [SouthWest, South, SouthEast, East, NorthEast, North, NorthWest, West])
					elif pos.z < 0:
						set_texture(player, [SouthEast, East, NorthEast, North, NorthWest, West, SouthWest, South])
				elif pos.x < 0:
					if abs(pos.z) < 0.5:
						set_texture(player, [North, NorthWest, West, SouthWest, South, SouthEast, East, NorthEast])
					elif pos.z > 0:
						set_texture(player, [NorthWest, West, SouthWest, South, SouthEast, East, NorthEast, North])
					elif pos.z < 0:
						set_texture(player, [NorthEast, North, NorthWest, West, SouthWest, South, SouthEast, East])

func everyone_in_game() -> bool:
	for player in GameManager.players.keys():
		if !GameManager.players[player]["in_game"]:
			return false
	return true

func set_texture(player, order:Array):
	if sideToMaterial[currentSide] == North:
		change_texture.rpc_id(int(player.name), order[0])
	elif sideToMaterial[currentSide] == NorthEast:
		change_texture.rpc_id(int(player.name), order[1])
	elif sideToMaterial[currentSide] == East:
		change_texture.rpc_id(int(player.name), order[2])
	elif sideToMaterial[currentSide] == SouthEast:
		change_texture.rpc_id(int(player.name), order[3])
	elif sideToMaterial[currentSide] == South:
		change_texture.rpc_id(int(player.name), order[4])
	elif sideToMaterial[currentSide] == SouthWest:
		change_texture.rpc_id(int(player.name), order[5])
	elif sideToMaterial[currentSide] == West:
		change_texture.rpc_id(int(player.name), order[6])
	elif sideToMaterial[currentSide] == NorthWest:
		change_texture.rpc_id(int(player.name), order[7])

@rpc("any_peer", "call_local")
func update():
	angle = round_to_dec(get_parent().rotation_degrees.y, 1)
	set_orientation.rpc(angle)
	
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

@rpc("any_peer", "call_local")
func set_orientation(m_angle:float):
	if m_angle >= -157.5 and m_angle <= -112.6:
		#print(get_parent().name, " looking NorthEast")
		currentSide = 2
	elif m_angle >= -112.5 and m_angle <= -67.6:
		#print(get_parent().name, " looking North")
		currentSide = 1
	elif m_angle >= -67.5 and m_angle <= -22.6:
		#print(get_parent().name, " looking NorthWest")
		currentSide = 0
	elif m_angle >= -22.5 and m_angle <= 22.4:
		#print(get_parent().name, " looking West")
		currentSide = 7
	elif m_angle >= 22.5 and m_angle <= 67.4:
		#print(get_parent().name, " looking SouthWest")
		currentSide = 6
	elif m_angle >= 67.5 and m_angle <= 112.4:
		#print(get_parent().name, " looking South")
		currentSide = 5
	elif m_angle >= 112.5 and m_angle <= 157.4:
		#print(get_parent().name, " looking SouthEast")
		currentSide = 4
	else: 
		#print(get_parent().name, " looking East")
		currentSide = 3

@rpc("any_peer","call_local")
func change_texture(texture:Texture):
		mat.albedo_texture = texture
		mesh.surface_set_material(0, mat)
