extends Node

const NORAY_ADDRESS = "tomfol.io"
const DEFAULT_PORT = 8890

# Max number of players.
const MAX_PEERS = 3

var peer = ENetMultiplayerPeer.new()

var is_host = false
var external_oid = ""
var server_started:bool = false

# Name for my player.
var player_name = "Player"

# Names for remote players in id:name format.
var players = {}

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
	#else: # Game is not in progress.
		## Unregister this player.
		#unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok_local():
	# We just connected to a server
	connection_succeeded.emit()

func _connected_ok_noray():
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	#game_error.emit("Server disconnected")
	peer.close()
	end_game()
	if is_multiplayer():
		unregister_player(1)

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

@rpc("any_peer")
func unregister_player(id):
	players.erase(id)
	if multiplayer.get_peers().is_empty():
		is_host = false
		peer.close()
	elif id != 1:
		multiplayer.multiplayer_peer.disconnect_peer(id)
	player_list_changed.emit()


@rpc("call_local")
func load_world():
	# Change scene.
	var world = load("res://Scenes/World.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

func host_game_local(new_player_name):
	#TODO : if server already created -> return error
	player_name = new_player_name
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.multiplayer_peer = peer
	is_host = true

func host_game_noray(new_player_name):
	player_name = new_player_name
	peer.create_server(Noray.local_port, MAX_PEERS)
	multiplayer.multiplayer_peer = peer
	is_host = true
	
func join_game_local(ip, new_player_name):
	player_name = new_player_name
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer

func join_game_noray(oid, new_player_name):
	player_name = new_player_name
	Noray.connect_nat(oid)
	external_oid = oid

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
		var spawn_pos: Vector3 = world.get_node("SubViewportContainer").get_node("SubViewport").get_node("Spawn").position
		var player = player_scene.instantiate()
		player.synced_position = spawn_pos
		player.name = str(p_id)
		world.get_node("SubViewportContainer").get_node("SubViewport").get_node("Players").add_child(player, true)
		print("spawned player with id: ", player.name)

func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	game_ended.emit()
	players.clear()


func _ready():
	Noray.on_connect_to_host.connect(_connected_ok_noray)
	Noray.on_connect_nat.connect(handle_nat_connection)
	Noray.on_connect_relay.connect(handle_relay_connection)
	
	Noray.connect_to_host(NORAY_ADDRESS, DEFAULT_PORT)
	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok_local)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

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

func is_multiplayer():
	if not players.keys().is_empty():
		_is_multiplayer.rpc_id(players.keys()[0])
		return server_started
	else:
		return false

@rpc("any_peer", "reliable")
func _is_multiplayer():
	server_started = multiplayer.multiplayer_peer != null
