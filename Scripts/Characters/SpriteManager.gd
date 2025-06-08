extends MeshInstance3D

@onready var _spritesDB:SpritesDB = $"/root/GameManager/SpritesDB"

@export var npc:bool
var mat:StandardMaterial3D
var angle:float
var pos:Vector3

@export_enum("Idle", "Walk", "Run") var state
var states:Array = ["Idle", "Walk", "Run"]
var animation_speed:float = 1.0

var sprites:Dictionary = {
	"Idle" : {
		"North": Texture.new(),
		"NorthEast": Texture.new(),
		"East": Texture.new(),
		"SouthEast": Texture.new(),
		"South": Texture.new(),
		"SouthWest": Texture.new(),
		"West": Texture.new(),
		"NorthWest": Texture.new()
	},
	"Walk" : {
		"North": Texture.new(),
		"NorthEast": Texture.new(),
		"East": Texture.new(),
		"SouthEast": Texture.new(),
		"South": Texture.new(),
		"SouthWest": Texture.new(),
		"West": Texture.new(),
		"NorthWest": Texture.new()
	},
	"Run" : {
		"North": Texture.new(),
		"NorthEast": Texture.new(),
		"East": Texture.new(),
		"SouthEast": Texture.new(),
		"South": Texture.new(),
		"SouthWest": Texture.new(),
		"West": Texture.new(),
		"NorthWest": Texture.new()
	}
}

var North
var NorthEast
var East
var SouthEast
var South
var SouthWest
var West
var NorthWest

var sideToMaterial:Array

var currentSide:int

func _ready() -> void:
	multiplayer.allow_object_decoding = true
	mat = mesh.surface_get_material(0).duplicate()
	set_sprites()

func set_sprites():
	for id in _spritesDB.DB.keys():
		if id == get_parent().name or id == get_parent().get_parent().name:
			for status in states:
				sprites[status]["North"] = _spritesDB.DB[id][status]["North"]
				sprites[status]["NorthEast"] = _spritesDB.DB[id][status]["NorthEast"]
				sprites[status]["East"] = _spritesDB.DB[id][status]["East"]
				sprites[status]["SouthEast"] = _spritesDB.DB[id][status]["SouthEast"]
				sprites[status]["South"] = _spritesDB.DB[id][status]["South"]
				sprites[status]["SouthWest"] = _spritesDB.DB[id][status]["SouthWest"]
				sprites[status]["West"] = _spritesDB.DB[id][status]["West"]
				sprites[status]["NorthWest"] = _spritesDB.DB[id][status]["NorthWest"]

func _process(_delta: float) -> void:
	North = sprites[states[state]]["North"]
	NorthEast = sprites[states[state]]["NorthEast"]
	East = sprites[states[state]]["East"]
	SouthEast = sprites[states[state]]["SouthEast"]
	South = sprites[states[state]]["South"]
	SouthWest = sprites[states[state]]["SouthWest"]
	West = sprites[states[state]]["West"]
	NorthWest = sprites[states[state]]["NorthWest"]
	
	sideToMaterial = [
		NorthWest,
		North,
		NorthEast,
		East,
		SouthEast,
		South,
		SouthWest,
		West
	]
	
	for side in sideToMaterial:
		if side is AnimatedTexture:
			side.speed_scale = animation_speed
	
	if npc or (1 in GameManager.players and GameManager.players[1]["solo"]):
		angle = round_to_dec(get_parent().rotation_degrees.y, 1)
		set_orientation(angle)
		change_solo()
		
	elif !npc and int(get_parent().name) in GameManager.players and GameManager.players[int(get_parent().name)]["in_game"]:
		update.rpc_id(int(get_parent().name))
		change()
	
func change():
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

func change_solo():
	for player in get_tree().get_nodes_in_group("Player"):
		if player.name != get_parent().name:
			pos = player.position.direction_to(global_position)
			if abs(pos.x) < 0.5:
				if pos.z > 0:
					set_texture_solo([West, SouthWest, South, SouthEast, East, NorthEast, North, NorthWest])
				elif pos.z < 0:
					set_texture_solo([East, NorthEast, North, NorthWest, West, SouthWest, South, SouthEast])
			elif pos.x > 0:
				if abs(pos.z) < 0.5:
					set_texture_solo([South, SouthEast, East, NorthEast, North, NorthWest, West, SouthWest])
				elif pos.z > 0:
					set_texture_solo([SouthWest, South, SouthEast, East, NorthEast, North, NorthWest, West])
				elif pos.z < 0:
					set_texture_solo([SouthEast, East, NorthEast, North, NorthWest, West, SouthWest, South])
			elif pos.x < 0:
				if abs(pos.z) < 0.5:
					set_texture_solo([North, NorthWest, West, SouthWest, South, SouthEast, East, NorthEast])
				elif pos.z > 0:
					set_texture_solo([NorthWest, West, SouthWest, South, SouthEast, East, NorthEast, North])
				elif pos.z < 0:
					set_texture_solo([NorthEast, North, NorthWest, West, SouthWest, South, SouthEast, East])


func set_texture(player, order:Array):
	if sideToMaterial[currentSide] == North and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[0])
	elif sideToMaterial[currentSide] == NorthEast and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[1])
	elif sideToMaterial[currentSide] == East and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[2])
	elif sideToMaterial[currentSide] == SouthEast and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[3])
	elif sideToMaterial[currentSide] == South and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[4])
	elif sideToMaterial[currentSide] == SouthWest and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[5])
	elif sideToMaterial[currentSide] == West and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[6])
	elif sideToMaterial[currentSide] == NorthWest and int(player.name) in GameManager.players:
		change_texture.rpc_id(int(player.name), order[7])

func set_texture_solo(order:Array):
	if sideToMaterial[currentSide] == North:
		change_texture(order[0])
	elif sideToMaterial[currentSide] == NorthEast:
		change_texture(order[1])
	elif sideToMaterial[currentSide] == East:
		change_texture(order[2])
	elif sideToMaterial[currentSide] == SouthEast:
		change_texture(order[3])
	elif sideToMaterial[currentSide] == South:
		change_texture(order[4])
	elif sideToMaterial[currentSide] == SouthWest:
		change_texture(order[5])
	elif sideToMaterial[currentSide] == West:
		change_texture(order[6])
	elif sideToMaterial[currentSide] == NorthWest:
		change_texture(order[7])


@rpc("any_peer", "call_local")
func update():
	angle = round_to_dec(get_parent().rotation_degrees.y, 1)
	set_orientation.rpc(angle)
	
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

@rpc("any_peer", "unreliable")
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
func change_texture(texture):
	mat.albedo_texture = texture
	mesh.surface_set_material(0, mat)
