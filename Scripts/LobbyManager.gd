extends Control

var is_online:bool = false

func _ready():
	# Called every time the node is added to the scene.
	GameManager.connection_failed.connect(_on_connection_failed)
	GameManager.connection_succeeded.connect(_on_connection_success)
	GameManager.player_list_changed.connect(refresh_lobby)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.game_error.connect(_on_game_error)
	
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Choice/Name.text = OS.get_environment("USERNAME")

func _on_solo_pressed() -> void:
	var player_name = $Connect/Name.text 
	GameManager.host_game_local(player_name)
	GameManager.begin_game()

func _on_lan_pressed() -> void:
	$Choice.hide()
	$Connect/Name.text = $Choice/Name.text
	$Connect/IPAddress.text = "127.0.0.1"
	$Connect.show()

func _on_online_pressed() -> void:
	$Choice.hide()
	$Connect/Name.text = $Choice/Name.text
	$Connect/IPAddress.text = "tomfol.io"
	is_online = true
	$Connect.show()

func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name = $Connect/Name.text
	if is_online:
		GameManager.host_game_noray(player_name)
		$Players/CopyOID.disabled = false
	else:
		GameManager.host_game_local(player_name)
		$Players/CopyOID.disabled = true
	refresh_lobby()


func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	
	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	var ip = $Connect/IPAddress.text
	if is_online:
		GameManager.join_game_noray(ip, player_name)
		$Players/CopyOID.disabled = false
	else:
		GameManager.join_game_local(ip, player_name)
		$Players/CopyOID.disabled = true

func _on_start_pressed():
	GameManager.begin_game()

func _on_copy_oid_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)

func _on_back_pressed() -> void:
	if $Connect.visible:
		$Choice/Name.text = $Connect/Name.text
		$Connect.hide()
		$Choice.show()
	elif $Players.visible:
		is_online = false
		if GameManager.is_host:
			if not multiplayer.get_peers().is_empty():
				for peer in multiplayer.get_peers():
					GameManager.unregister_player(peer)
				multiplayer.server_disconnected.emit()
			else:
				GameManager.unregister_player(1)
		else:
			GameManager.unregister_player.rpc(multiplayer.get_unique_id())
			GameManager.end_game()


func refresh_lobby():
	var players = GameManager.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(GameManager.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)
	
	if GameManager.is_multiplayer():
		$Players/Start.disabled = not multiplayer.is_server()


func _on_connection_success():
	$Connect.hide()
	$Players.show()

func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")

func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
