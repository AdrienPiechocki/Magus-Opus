extends Node

@onready var environement:WorldEnvironment = $"/root/World/WorldEnvironment"
@onready var brightness = $Menu/Settings/BrightnessSlider
@onready var config_manager = GameManager.get_node("ConfigManager")

func _ready() -> void:
	brightness.value = config_manager.settings["Graphics"]["brightness"]
	environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)

func _on_exit_pressed() -> void:
	if multiplayer.get_unique_id() == 1:
		GameManager.unregister_player(1)
	else:
		GameManager.unregister_player.rpc(multiplayer.get_unique_id())
	
func _on_back_pressed() -> void:
	$".".hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_parent().can_move = true

func _on_brightness_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)
		config_manager.settings["Graphics"]["brightness"] = brightness.value
		config_manager.save_config()
