extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 4242

# Max number of players.
const MAX_PEERS = 3

var peer = null

# Name for my player.
var player_name = "Krash Test"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)
	
# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	game_error.emit("Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.set_network_peer(null) # Remove peer
	connection_failed.emit()


# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()
	print("Player ", new_player_name, " connected with ID ", id)

func unregister_player(id):
	players.erase(id)
	player_list_changed.emit()


@rpc("call_local")
func load_world():
	# Change scene.
	var world = load("res://Scenes/World.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

func host_game(new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.multiplayer_peer = peer

func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer


func get_player_list():
	return players.values()


func get_player_name():
	return player_name

func begin_game():
	assert(multiplayer.is_server())
	load_world.rpc()
	
	var world = get_tree().get_root().get_node("World")
	var player_scene = load("res://Prefabs/player.tscn")
	
	var spawns := [1]
	for p: int in players:
		spawns.append(p)

	for p_id: int in spawns:
		var spawn_pos: Vector3 = world.get_node("Spawn").position
		var player = player_scene.instantiate()
		player.synced_position = spawn_pos
		player.name = str(p_id)
		world.get_node("Players").add_child(player, true)
		print("spawned player with id: ", player.name)

func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	game_ended.emit()
	players.clear()


func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
