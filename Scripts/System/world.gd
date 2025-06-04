extends Node3D

@onready var players_node:Node3D = $Players
var player_scene: PackedScene = preload("res://Prefabs/Players/player.tscn")

func _ready():
	if multiplayer.is_server():
		if GameManager.players[1]["solo"]:
			spawn_player(1, GameManager.players[1]["data"])
		else: 
			for id in GameManager.non_server_players:
				spawn_player(id, GameManager.players[id]["data"])
			
	elif GameManager.join_in_game:
		request_spawn.rpc_id(1, multiplayer.get_unique_id())
		
		
func _spawn_player_for_all(id: int):
	if not GameManager.players.has(id):
		push_warning("ID ", id, " not found")
		return
	var data = GameManager.players[id]["data"]
	spawn_player.rpc(id, data)  # client side
	if multiplayer.is_server():
		spawn_player(id, data)   # server side

@rpc("any_peer")
func spawn_player(id: int, data: Dictionary):
	if players_node.has_node(str(id)):
		print("Player already exists, ID: ", id)
		return
	var player = player_scene.instantiate()
	for key in data:
		player.set(str(key), data[key])
	player.set_multiplayer_authority(id)
	player.name = str(id)
	players_node.add_child.call_deferred(player)
	print("Player spawned with ID: ", id)


@rpc("any_peer")
func request_spawn(id: int):
	if not multiplayer.is_server():
		print("ERROR : request spawn called from client !")
		return

	print("Recived spawn request for ID :", id)

	if not GameManager.players.has(id):
		push_warning("ID ", id, " unknown")
		return

	if GameManager.players[id].get("in_game", false):
		print("Player with ID ", id, " is already in game")
		return
		
	# New client recives other players in game:
	for pid in GameManager.non_server_players:
		if pid != id and GameManager.players[pid]["in_game"]:
			spawn_player.rpc_id(id, pid, GameManager.players[pid]["data"])
	GameManager.players[id]["in_game"] = true
	_spawn_player_for_all(id)
