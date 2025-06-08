extends Control

var ready_style:StyleBoxFlat = StyleBoxFlat.new()
@onready var default_color:Color = $Choice.get_theme_stylebox("panel").bg_color

func _ready():
	# Called every time the node is added to the scene.
	GameManager.connection_failed.connect(_on_connection_failed)
	GameManager.connection_succeeded.connect(_on_connection_success)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.game_error.connect(_on_game_error)
	GameManager.players_list_changed.connect(refresh_lobby)
	# Set the player name according to the system username
	if OS.has_environment("USERNAME"):
		$Choice/Name.text = OS.get_environment("USERNAME")

func _on_solo_pressed() -> void:
	var player_name = $Choice/Name.text 
	GameManager.peer.close()
	GameManager.players = {1: {"name": player_name, 
								"solo": true,
								"dedicated_server": false,
								"password": "",
								"ready": false, 
								"in_game": false, 
								"data": {"position": Vector3(0, 1, 0),
										"rotation": Vector3(0, 0, 0),
										"lantern_lit": false,
										"in_menu": false
									}
							}}
	GameManager.begin_solo()

func _on_multiplayer_pressed() -> void:
	$Choice.hide()
	$Connect/Name.text = $Choice/Name.text
	$Connect/IPAddress.text = "127.0.0.1"
	$Connect.show()

func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()

	var player_name = $Connect/Name.text
	var password = $Connect/Password.text
	GameManager.host_game(player_name, password)


func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	var ip = $Connect/IPAddress.text
	var password = $Connect/Password.text
	GameManager.join_game(ip, player_name, password)

func _on_back_pressed() -> void:
	$Choice/Name.text = $Connect/Name.text
	if $Connect.visible:
		$Connect.hide()
		$Choice.show()
	elif $Players.visible:
		if GameManager.is_host and not multiplayer.get_peers().is_empty():
			for peer in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(peer)
		multiplayer.multiplayer_peer.close()
		
		
func refresh_lobby():
	var players:Array = []
	for id in GameManager.players.keys():
		if id != multiplayer.get_unique_id() and not GameManager.players[id]["dedicated_server"]:
			players.append(GameManager.players[id]["name"])
	players.sort()
	
	var ids = []
	for id in GameManager.players.keys():
		if id != multiplayer.get_unique_id() and not GameManager.players[id]["dedicated_server"]:
			ids.append(id)
	
	$Players/List.clear()
	$Players/List.add_item(GameManager.get_player_name() + " (You)")
	$Players/List.set_item_custom_bg_color(0, Color.CYAN)
	$Players/List.set_item_selectable(0, false)
	for p in players:
		$Players/List.add_item(p)
		for id in ids:
			if GameManager.players[id]["name"] == p:
				var item = ids.bsearch(id)+1
				$Players/List.set_item_selectable(item, false)
				$Players/List.set_item_custom_bg_color(item, (Color.LIME_GREEN if GameManager.players[id]["ready"] else Color.LIGHT_YELLOW))

func _on_connection_success():
	$Connect.hide()
	$Players.show()

func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	_on_game_error("Can't join server")


func _on_game_ended():
	show()
	$Choice.show()
	$Connect.hide()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _process(_delta: float) -> void:
	if 1 in GameManager.players.keys() and GameManager.players[1]["solo"]:
		return
	if GameManager.server_started:
		$Players/Start.disabled = (not multiplayer.is_server() if multiplayer.get_peers().is_empty() else not (verify_ready() and multiplayer.is_server()))
		$Players/Ready.disabled = (multiplayer.is_server() if multiplayer.get_peers().is_empty() else false)
	else:
		for player in GameManager.players.keys():
			GameManager.players[player]["ready"] = false
		$Players/Ready.button_pressed = false
				
func verify_ready() -> bool:
	for player in GameManager.players.keys():
		if not GameManager.players[player]["ready"]:
			return false
	return true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_ready_toggled(toggled_on: bool) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		toggle_ready.rpc(toggled_on)
	ready_style.bg_color = (Color.LIME_GREEN if toggled_on else default_color)
	$Players/Ready.add_theme_stylebox_override("pressed", ready_style)
	
@rpc("any_peer", "call_local")
func toggle_ready(toggle:bool):
	if toggle:
		print(multiplayer.get_remote_sender_id(), " is ready !")
		GameManager.players[multiplayer.get_remote_sender_id()]["ready"] = true
	else:
		print(multiplayer.get_remote_sender_id(), " isn't ready...")
		GameManager.players[multiplayer.get_remote_sender_id()]["ready"] = false
	
	var ids:Array = []
	for id in GameManager.players.keys():
		if id != multiplayer.get_unique_id() and not GameManager.players[id]["dedicated_server"]:
			ids.append(id)
	
	for id in ids:
		if id == multiplayer.get_remote_sender_id():
			var item = ids.bsearch(id)+1
			$Players/List.set_item_custom_bg_color(item, (Color.LIME_GREEN if toggle else Color.LIGHT_YELLOW))
	
	for player in GameManager.players.keys():
		if GameManager.players[player]["in_game"]:
			if GameManager.players[multiplayer.get_unique_id()]["ready"]:
				GameManager.load_world()
				GameManager.player_joined_in_game.emit()
				GameManager.join_existing_game.rpc_id(1)
				return

func _on_start_pressed() -> void:
	GameManager.begin_game()

func _on_hide_toggled(toggled_on: bool) -> void:
	$Connect/Password.secret = toggled_on
