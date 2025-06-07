extends Node

@onready var environement:WorldEnvironment = $"/root/World/WorldEnvironment"
@onready var brightness = $Menu/Settings/BrightnessSlider
@onready var config_manager = GameManager.get_node("ConfigManager")
@onready var light_meter = $HUD/LightMeter
@onready var _player:Player = $"../.."

func _ready() -> void:
	brightness.value = config_manager.settings["Graphics"]["brightness"]
	environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)

func _process(_delta: float) -> void:
	light_meter.value = _player.light_level

func _on_exit_pressed() -> void:
	if 1 in GameManager.players and GameManager.players[1]["solo"]:
		GameManager.players[1]["in_game"] = false
		GameManager.end_game()
	else:
		GameManager.players[multiplayer.get_unique_id()]["in_game"] = false
		multiplayer.multiplayer_peer.close()
	
func _on_back_pressed() -> void:
	$Menu.hide()
	_player.Inputs.in_menu = false

func _on_brightness_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		environement.environment.adjustment_brightness = brightness.value
		config_manager.settings["Graphics"]["brightness"] = brightness.value
		config_manager.save_config()
