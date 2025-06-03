extends Node

@onready var environement:WorldEnvironment = $"/root/World/WorldEnvironment"
@onready var brightness = $Menu/Settings/BrightnessSlider
@onready var config_manager = GameManager.get_node("ConfigManager")

func _ready() -> void:
	brightness.value = config_manager.settings["Graphics"]["brightness"]
	environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)

func _on_exit_pressed() -> void:
	if GameManager.players[1]["solo"]:
		GameManager.end_game()
	else:
		multiplayer.multiplayer_peer.close()
	
func _on_back_pressed() -> void:
	$".".hide()
	get_parent().in_menu = false

func _on_brightness_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)
		config_manager.settings["Graphics"]["brightness"] = brightness.value
		config_manager.save_config()
