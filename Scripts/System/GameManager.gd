extends Node

const NORAY_ADDRESS:String = "tomfol.io"
const DEFAULT_PORT:int = 8890

# Max number of peers.
const MAX_PEERS:int = 3

var peer:ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var is_host:bool = false
var external_oid:String = ""
@export var server_started:bool = false
@export var join_in_game:bool = false

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

func _ready():
	if OS.has_feature("dedicated_server"):
		host_game_local("server")
		players[1]["dedicated_server"] = true
		players[1]["ready"] = true
		load_world.call_deferred()
		print("server running")
	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok_local)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _process(_delta: float) -> void:
	non_server_players = players.keys().filter(func(id): return !players[id]["dedicated_server"])
	if OS.has_feature("dedicated_server") and server_started:
		if check_ready():
			for player in players.keys():
				if not players[player]["in_game"] and not players[player]["dedicated_server"]:
					print("load world for ", player)
					players[player]["in_game"] = true
					join_in_game = true
					load_world.rpc_id(player)
					
	if not players.keys().is_empty():
		server_started = true
		
		var flag1 = false
		var flag2 = false
		for player in GameManager.players.keys():
			if not GameManager.players[player]["in_game"]:
				flag1 = true
			else:
				flag2 = true
		if flag1 and flag2:
			join_in_game = true
	else:
		server_started = false
		join_in_game = false
		

func check_ready() -> bool:
	for player in non_server_players:
		if not players[player]["ready"]:
			return false
	return true

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
	
func _connected_ok_local():
	connection_succeeded.emit()

func _connected_ok_noray():
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()

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

func host_game_local(new_player_name):
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
	
func host_game_noray(new_player_name):
	player_name = new_player_name
	peer.create_server(Noray.local_port, MAX_PEERS)
	multiplayer.multiplayer_peer = peer
	is_host = true
	_player_connected(1)
	
func join_game_local(ip, new_player_name):
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(timeout)
	player_name = new_player_name
	var err = peer.create_client(ip, DEFAULT_PORT)
	if err:
		game_error.emit("Can't join server")
		end_game()
		return err
	multiplayer.multiplayer_peer = peer
	print(player_name, " joined game")
	await players_list_changed
	for player in players.keys():
		if players[player]["in_game"]:
			load_world()
			return

func timeout():
	if multiplayer.get_unique_id() not in players.keys():
		multiplayer.multiplayer_peer.close()

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


@rpc("any_peer", "call_local")
func load_world():
	for player in players:
		players[player]["in_game"] = true
		players[player]["ready"] = true
	var _world = world.instantiate()
	if get_tree().get_root().has_node("World"):
		get_tree().get_root().get_node("World").free()
	get_tree().get_root().add_child(_world)
	get_tree().get_root().get_node("Lobby").hide()
	if join_in_game:
		join_game.rpc_id(1)
	else:
		begin_game()

func begin_game():

	var _world = get_tree().get_root().get_node("World")
	
	var spawns := []
	for p: int in players:
		spawns.append(p)

	for p_id: int in spawns:
		var player = player_scene.instantiate()
		player.name = str(p_id)
		for key in players[p_id]["data"]:
			player.set(str(key), players[p_id]["data"][key])
		_world.get_node("Players").add_child(player, true)
		print("spawned player with id: ", player.name)

@rpc("any_peer")
func join_game():
	var id = multiplayer.get_remote_sender_id()
	for pid in non_server_players:
		if pid != id and players[pid]["in_game"]:
			spawn_player.rpc_id(id, pid, GameManager.players[pid]["data"])
	players[multiplayer.get_unique_id()]["in_game"] = true
	spawn_player.rpc(id, GameManager.players[id]["data"])

@rpc("any_peer", "call_local")
func spawn_player(id: int, data: Dictionary):
	var _world = get_tree().get_root().get_node("World")
	var player = player_scene.instantiate()
	for key in data:
			player.set(str(key), data[key])
	player.set_multiplayer_authority(id)
	player.name = str(id)
	_world.get_node("Players").add_child(player, true)
	print("spawned player with id:", id)	

	
func end_game():
	if get_tree().get_root().has_node("World"):
		get_tree().get_root().get_node("World").queue_free()
	get_tree().get_root().get_node("Lobby").show()
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
