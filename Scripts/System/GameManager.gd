extends Node

const NORAY_ADDRESS:String = "tomfol.io"
const DEFAULT_PORT:int = 8890

# Max number of peers.
const MAX_PEERS:int = 3

var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var is_host:bool = false
var external_oid:String = ""
@export var server_started:bool = false

# Name for my player.
var player_name:String = "Player"

# Names for remote players in id:name format.
@export var players:Dictionary = {}
@export var non_server_players:Array 

var world:PackedScene = preload("res://Scenes/World.tscn")
var player_scene:PackedScene = preload("res://Prefabs/Players/player.tscn")

# Signals to let lobby GUI know what's going on.
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal players_list_changed()
signal player_joined_in_game()

func _ready():
	if OS.has_feature("dedicated_server"):
		var arguments = {}
		var password = ""
		for argument in OS.get_cmdline_args():
			if argument.find("=") > -1:
				var key_value = argument.split("=")
				arguments[key_value[0].lstrip("--")] = key_value[1]
		if "password" in arguments.keys():
			password = arguments["password"]
		host_game("server", password)
		players[1]["dedicated_server"] = true
		begin_game.call_deferred()
		print("server running")
	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _process(_delta: float) -> void:
	non_server_players = players.keys().filter(func(id): return !players[id]["dedicated_server"])
	if OS.has_feature("dedicated_server") and server_started:
		for player in non_server_players:
			if not players[player]["in_game"] and players[player]["ready"]:
				print("load world for ", player)
				load_world.rpc_id(player)
				player_joined_in_game.emit()
				players[player]["in_game"] = true
				join_existing_game.rpc_id(1)
				
	server_started = !players.keys().is_empty()


func _player_connected(id):
	print("player connected")
	register_player.rpc_id(id, player_name)
	await get_tree().create_timer(0.1).timeout
	players_list_changed.emit()

func _player_disconnected(id):
	print("player disconnected")
	
	if players[id]["in_game"]:
		game_error.emit("Player " + players[id]["name"] + " disconnected")
	remove_player(id)
	unregister_player.rpc(id)
	await get_tree().create_timer(0.1).timeout
	players_list_changed.emit()
	
func _connected_ok():
	connection_succeeded.emit()

func _server_disconnected():
	if is_host:
		print("server disconnected")
		is_host = false
		peer.close()
	end_game()

func _connected_fail():
	connection_failed.emit()

@rpc("any_peer", "call_local")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	if id in players.keys():
		return
	players[id] = {"name": new_player_name, 
					"solo": false,
					"dedicated_server": false,
					"ready": false, 
					"in_game": false, 
					"password": "",
					"data": {"position": Vector3(0, 1, 0),
							"rotation": Vector3(0, 0, 0),
							"lantern_lit": false,
							"in_menu": false
						}
				}
	print("Player ", new_player_name, " connected with ID ", id)
	
@rpc("any_peer", "call_local")
func unregister_player(id):
	print("unregistering player ", id)
	players.erase(id)
	
@rpc("any_peer","call_local")
func remove_player(id):
	for player in get_tree().get_nodes_in_group("Player"):
		if int(player.name) == id:
			player.queue_free()
			print("player ", player.name, " removed")

func host_game(new_player_name, password):
	player_name = new_player_name
	var err = peer.create_server(DEFAULT_PORT, MAX_PEERS)
	if err != OK:
		game_error.emit("Can't create server")
		end_game()
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	_player_connected(1)
	print(player_name, " hosting game")
	await players_list_changed
	players[1]["password"] = password

func join_game(ip, new_player_name, password):
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(timeout)
	player_name = new_player_name
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	print(player_name, " joined game")
	await players_list_changed
	await get_tree().process_frame
	if players[1]["password"] != "":
		if password != players[1]["password"]:
			multiplayer.multiplayer_peer.close()
			game_error.emit("WRONG PASSWORD")
	

func timeout():
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if multiplayer.get_unique_id() not in players.keys():
		multiplayer.multiplayer_peer.close()


func get_player_list():
	var names := []
	for id in players.keys():
		names.append(players[id]["name"])
	return names
	
func get_player_name():
	return player_name


@rpc("any_peer", "call_local")
func load_world():
	if get_tree().get_root().has_node("World"):
		return
	var _world = world.instantiate()
	get_tree().get_root().add_child(_world)
	get_tree().get_root().get_node("Lobby").hide()
	
func begin_game():
	assert(multiplayer.is_server())
	load_world.rpc()
	var _world = get_tree().get_root().get_node("World")
	
	var spawns := []
	for p: int in players:
		spawns.append(p)

	for p_id: int in spawns:
		spawn_player(p_id, GameManager.players[p_id]["data"])

@rpc("any_peer", "call_local")
func join_existing_game():
	var id = multiplayer.get_remote_sender_id()
	# send existing players to new client
	for pid in non_server_players:
		if pid != id and players[pid]["in_game"]:
			spawn_player.rpc_id(id, pid, GameManager.players[pid]["data"])
	# send new player to existing clients
	for pid in non_server_players:
		if pid != id and players[pid]["in_game"]:
			spawn_player.rpc_id(pid, id, GameManager.players[id]["data"])
	# spawn new player locally
	spawn_player.rpc_id(id, id, GameManager.players[id]["data"])

func begin_solo():
	load_world()
	var _world = get_tree().get_root().get_node("World")
	_world.get_node("MultiplayerSpawner").free()
	spawn_player(1, GameManager.players[1]["data"])

@rpc("authority", "call_local")
func spawn_player(id: int, data: Dictionary):
	if players[id]["dedicated_server"]:
		return
	var players_root = get_tree().get_root().get_node("World/Players")
	var existing = players_root.get_node_or_null(str(id))
	if existing:
		if is_instance_valid(existing):
			print("Player with ID ", id, " already spawned. Ignoring.")
			return
		else:
			print("Removing invalid reference for player", id)
			existing.queue_free()
			await get_tree().process_frame
	
	var player = player_scene.instantiate()
	player.name = str(id)
	players_root.add_child(player, true)
	for key in data:
		player.set(str(key), data[key])
	players[id]["in_game"] = true
	players[id]["ready"] = true
	print("spawned player with id:", id)	

	
func end_game():
	if get_tree().get_root().has_node("World"):
		get_tree().get_root().get_node("World").queue_free()
	get_tree().get_root().get_node("Lobby").show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_ended.emit()
	players.clear()
