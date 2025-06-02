extends Node3D

@onready var players_node:Node3D = $Players
var player_scene: PackedScene = preload("res://Prefabs/Players/player.tscn")

func _ready():
	if multiplayer.is_server():
		# Spawn tous les joueurs déjà en jeu au lancement serveur
		for id in GameManager.players.keys():
			if GameManager.players[id]["in_game"]:
				spawn_player(id, GameManager.players[id]["data"])
	else:
		# Client demande à rejoindre
		rpc_id(1, "request_spawn", multiplayer.get_unique_id())

# Crée un joueur côté serveur et prévient tous les clients
func _spawn_player_for_all(id: int):
	spawn_player.rpc(id, GameManager.players[id]["data"])

# RPC : spawn le joueur côté client
@rpc("any_peer")
func spawn_player(id: int, data: Dictionary):
	var player = player_scene.instantiate()
	for key in data:
		player.set(str(key), data[key])
	player.set_multiplayer_authority(id)
	player.name = str(id)
	players_node.add_child(player)
	print("Player spawned locally with id:", id)

# RPC : spawn le joueur côté client
@rpc("any_peer", "call_local")
func spawn_player2(id: int, data: Dictionary):
	var player = player_scene.instantiate()
	for key in data:
		player.set(str(key), data[key])
	player.set_multiplayer_authority(id)
	player.name = str(id)
	players_node.add_child(player)
	print("Player spawned locally with id:", id)


# Client demande au serveur de spawn son joueur
@rpc("any_peer")
func request_spawn(id: int):
	# Serveur met à jour la liste des joueurs s’il faut
	# (exemple simple, ici on suppose qu'il existe déjà)
	print("Spawn request received for id:", id)
	if GameManager.join_in_game:
		spawn_player2.rpc(id, GameManager.players[id]["data"])
	else:
		spawn_player.rpc(id, GameManager.players[id]["data"])
	# Envoie au nouveau client la liste des autres joueurs déjà présents
	for pid in GameManager.players.keys():
		if GameManager.players[pid]["in_game"] and pid != id:
			spawn_player.rpc_id(id, pid, GameManager.players[pid]["data"])
