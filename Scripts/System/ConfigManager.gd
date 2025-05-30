extends Node

func _ready() -> void:
	load_config()

func load_config():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	#if config doesn't exist, create config
	if err != OK:
		create_config(config)

	#load config values
	GameManager.graphics_settings["brightness"] = config.get_value("Graphics", "brightness")

func create_config(config:ConfigFile):
	#create default values
	config.set_value("Graphics", "brightness", 0.0)
	
	#save config
	config.save("user://settings.cfg")

func save_config():
	var config = ConfigFile.new()
	for key in GameManager.graphics_settings.keys():
		config.set_value("Graphics", key, GameManager.graphics_settings[key])
	
	#save config
	config.save("user://settings.cfg")
