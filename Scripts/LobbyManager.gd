extends Control

var is_online:bool = false
var ready_style:StyleBoxFlat = StyleBoxFlat.new()
@onready var default_color:Color = $Choice.get_theme_stylebox("panel").bg_color

func _ready():
	# Called every time the node is added to the scene.
	GameManager.connection_failed.connect(_on_connection_failed)
	GameManager.connection_succeeded.connect(_on_connection_success)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.game_error.connect(_on_game_error)
	
	# Set the player name according to the system username
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
		
		
func refresh_lobby():
	var players = GameManager.get_player_list()
	players.sort()
	$Players/List.clear()
	#$Players/List.add_item(GameManager.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)

func _on_connection_success():
	$Connect.hide()
	$Players.show()

func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")

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
	if GameManager.server_started:
		refresh_lobby()
		$Players/Start.disabled = (not multiplayer.is_server() if multiplayer.get_peers().is_empty() else not (verify_ready() and multiplayer.is_server()))
		$Players/Ready.disabled = (multiplayer.is_server() if multiplayer.get_peers().is_empty() else false)
	else:
		GameManager.players_ready = []
		$Players/Ready.button_pressed = false
				
func verify_ready() -> bool:
	for player in GameManager.players.keys():
		if player not in GameManager.players_ready:
			return false
	return true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_ready_toggled(toggled_on: bool) -> void:
	toggle_ready.rpc(toggled_on)
	ready_style.bg_color = (Color.LIME_GREEN if toggled_on else default_color)
	$Players/Ready.add_theme_stylebox_override("pressed", ready_style)
	
@rpc("any_peer", "call_local")
func toggle_ready(toggle:bool):
	if toggle:
		print(multiplayer.get_remote_sender_id(), " is ready !")
		GameManager.players_ready.append(multiplayer.get_remote_sender_id())
	else:
		print(multiplayer.get_remote_sender_id(), " isn't ready...")
		GameManager.players_ready.erase(multiplayer.get_remote_sender_id())

func _on_start_pressed() -> void:
	GameManager.begin_game()
