extends MeshInstance3D

var mat:StandardMaterial3D

@export var North:Texture
@export var NorthEast:Texture
@export var East:Texture
@export var SouthEast:Texture
@export var South:Texture
@export var SouthWest:Texture
@export var West:Texture
@export var NorthWest:Texture

var pos:Vector3

@onready var head = $"../head"

func _ready() -> void:
	mat = mesh.surface_get_material(0).duplicate()
	
func _process(_delta: float) -> void:
	for player in get_tree().get_nodes_in_group("Player"):
		if player.is_multiplayer_authority():
			pos = player.position.direction_to(global_position)
			#print(round(pos), "  ", round(head.global_rotation_degrees.y))
			change_texture.rpc_id(int(player.name), pos.x, pos.z)
	
@rpc("call_local")
func change_texture(a:float, b:float):
	if abs(a) < 0.5:
		if b > 0:
			mat.albedo_texture = West
			mesh.surface_set_material(0, mat)
		elif b < 0:
			mat.albedo_texture = East
			mesh.surface_set_material(0, mat)
	elif a > 0:
		if abs(b) < 0.5:
			mat.albedo_texture = South
			mesh.surface_set_material(0, mat)
		elif b > 0:
			mat.albedo_texture = SouthWest
			mesh.surface_set_material(0, mat)
		elif b < 0:
			mat.albedo_texture = SouthEast
			mesh.surface_set_material(0, mat)
		
	elif a < 0:
		if abs(b) < 0.5:
			mat.albedo_texture = North
			mesh.surface_set_material(0, mat)
		elif b > 0:
			mat.albedo_texture = NorthWest
			mesh.surface_set_material(0, mat)
		elif b < 0:
			mat.albedo_texture = NorthEast
			mesh.surface_set_material(0, mat)
