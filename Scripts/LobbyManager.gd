extends Control

func _ready():
	# Called every time the node is added to the scene.
	GameManager.connection_failed.connect(_on_connection_failed)
	GameManager.connection_succeeded.connect(_on_connection_success)
	GameManager.player_list_changed.connect(refresh_lobby)
	GameManager.game_ended.connect(_on_game_ended)
	GameManager.game_error.connect(_on_game_error)
	
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	
	$Connect/IPAddress.text = "tomfol.io"

func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name = $Connect/Name.text
	var ip = $Connect/IPAddress.text
	if not ip.is_valid_ip_address():
		GameManager.host_game_noray(player_name)
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
	if not ip.is_valid_ip_address():
		GameManager.join_game_noray(ip, player_name)
	else:
		GameManager.join_game_local(ip, player_name)
		$Players/CopyOID.disabled = true


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


func refresh_lobby():
	var players = GameManager.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(GameManager.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not multiplayer.is_server()


func _on_start_pressed():
	GameManager.begin_game()


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")

func _on_copy_oid_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)
