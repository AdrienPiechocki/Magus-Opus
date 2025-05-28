extends Node

@onready var environement:WorldEnvironment = $"/root/World/WorldEnvironment"
@onready var brightness = $Menu/Settings/BrightnessSlider

func _ready() -> void:
	brightness.value = GameManager.graphics_settings["brightness"]
	environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)

func _on_exit_pressed() -> void:
	GameManager.unregister_player.rpc(multiplayer.get_unique_id())
	GameManager.end_game()
	
func _on_back_pressed() -> void:
	$".".hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_brightness_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		environement.environment.ambient_light_color = Color(brightness.value, brightness.value, brightness.value)
		GameManager.graphics_settings["brightness"] = brightness.value
		GameManager.save_config()
