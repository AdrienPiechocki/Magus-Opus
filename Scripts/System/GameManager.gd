extends Node

const NORAY_ADDRESS:String = "tomfol.io"
const DEFAULT_PORT:int = 8890

# Max number of players.
const MAX_PLAYERS:int = 4

var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var is_host:bool = false
var external_oid:String = ""
@export var server_started:bool = false
var was_in_game:bool = false
var can_connect:bool = true

# Name for my player.
var player_name:String = "Player"

# Names for remote players in id:name format.
@export var players:Dictionary = {}

var world:PackedScene = preload("res://Scenes/World.tscn")
var player_scene:PackedScene = preload("res://Prefabs/Players/player.tscn")

# Signals to let lobby GUI know what's going on.
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

func _ready():
	Noray.on_connect_to_host.connect(_connected_ok_noray)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	
	Noray.connect_to_host(NORAY_ADDRESS, DEFAULT_PORT)
	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.connected_to_server.connect(_connected_ok_local)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _process(_delta: float) -> void:
	if get_player_list().size() > MAX_PLAYERS:
		if players.keys()[-1] == multiplayer.get_unique_id():
			unregister_player.rpc(multiplayer.get_unique_id())
			game_error.emit("Server full")
			end_game() 
			
	if not players.keys().is_empty():
		server_started = true
	else:
		server_started = false

@rpc("any_peer")
func _player_connected(_id):
	register_player.rpc(player_name)

func _player_disconnected(id):
	if was_in_game:
		game_error.emit("Player " + players[id]["name"] + " disconnected")
	remove_player(id)
	multiplayer.disconnect_peer(id)

@rpc("any_peer","call_local")
func remove_player(id):
	was_in_game = false
	players.erase(id)
	for player in get_tree().get_nodes_in_group("Player"):
		if int(player.name) == id:
			player.queue_free()

func _connected_ok_local():
	connection_succeeded.emit()

func _connected_ok_noray():
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()

func _server_disconnected():
	if not multiplayer.get_peers().is_empty():
		game_error.emit("Server disconnected")
	peer.close()
	end_game()

func _connected_fail():
	connection_failed.emit()

@rpc("any_peer")
func register_player(new_player_name):
	var id = (1 if multiplayer.get_remote_sender_id() == 0 else multiplayer.get_remote_sender_id())
	players[id] = {"name": new_player_name, "ready": false, "in_game": false}
	print("Player ", new_player_name, " connected with ID ", id)
	
	
@rpc("any_peer")
func unregister_player(id):
	if id == 1:
		is_host = false
		_server_disconnected()
	else:
		if players[multiplayer.get_remote_sender_id()]["in_game"]:
			was_in_game = true
		_player_disconnected(id)


func host_game_local(new_player_name):
	player_name = new_player_name
	var err = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if err != OK:
		game_error.emit("Can't create server")
		end_game()
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	register_player(player_name)
	
func host_game_noray(new_player_name):
	player_name = new_player_name
	peer.create_server(Noray.local_port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	is_host = true
	register_player(player_name)
	
func join_game_local(ip, new_player_name):
	player_name = new_player_name
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer

func join_game_noray(oid, new_player_name):
	player_name = new_player_name
	Noray.connect_nat(oid)
	external_oid = oid

func get_player_list():
	var names := []
	for id in players.keys():
		names.append(players[id]["name"])
	return names
	
func get_player_name():
	return player_name


@rpc("call_local")
func load_world():
	# Change scene.
	get_tree().get_root().add_child(world.instantiate())
	get_tree().get_root().get_node("Lobby").hide()

func begin_game():
	assert(multiplayer.is_server())
	for player in players.keys():
		players[player]["in_game"] = true
	load_world.rpc()
	
	var _world = get_tree().get_root().get_node("World")
	
	var spawns:Array = []
	for p: int in players.keys():
		spawns.append(p)
	
	for p_id: int in spawns:
		var spawn_pos: Vector3 = _world.get_node("Spawn").position
		var player = player_scene.instantiate()
		player.synced_position = spawn_pos
		player.name = str(p_id)
		_world.get_node("Players").add_child(player, true)
		print("spawned player with id: ", player.name)

@rpc("any_peer", "call_local")
func join_game():
	players[multiplayer.get_remote_sender_id()]["in_game"] = true
	load_world.rpc()
	var _world = get_tree().get_root().get_node("World")
	var spawn_pos: Vector3 = _world.get_node("Spawn").position
	var player = player_scene.instantiate()
	player.synced_position = spawn_pos
	player.name = str(multiplayer.get_remote_sender_id())
	_world.get_node("Players").add_child(player)
	print("spawned player with id: ", player.name)

@rpc("any_peer")
func end_game():
	for player in players.keys():
		if player == multiplayer.get_remote_sender_id():
			players[player]["in_game"] = false
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_ended.emit()
	players.clear()

### NORAY CONNEXION MANAGMENT :

func handle_nat_connection(address, port):
	var err = await connect_to_server(address, port)
	
	if err != OK && !is_host:
		print("NAT failed, using relay")
		Noray.connect_relay(external_oid)
		err = OK
	
	return err

func handle_relay_connection(address, port):
	var err = await connect_to_server(address, port)
	if err != OK && !is_host:
		game_error.emit("Couldn't connect")
	return err

func connect_to_server(address, port):
	var err = OK
	
	if !is_host:
		var udp = PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(address, port)
		
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		
		if err != OK:
			if err != ERR_BUSY:
				print("Handshake failed")
				return err
		else:
			print("Handshake success")
		
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		
		if err != OK:
			return err
		
		multiplayer.multiplayer_peer = peer
		
		return OK
	else:
		err = await PacketHandshake.over_enet(multiplayer.multiplayer_peer.host, address, port)
	
	return err
