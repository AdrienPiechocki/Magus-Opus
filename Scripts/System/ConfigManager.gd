extends Node

var settings:Dictionary = {}

func _ready() -> void:
	load_config()

func load_config():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	#if config doesn't exist, create config
	if err != OK:
		create_config(config)

	#load config values
	settings["Graphics"] = {
		"brightness": config.get_value("Graphics", "brightness"),
		}

func create_config(config:ConfigFile):
	#create default values
	config.set_value("Graphics", "brightness", 0.0)
	
	#save config
	config.save("user://settings.cfg")

func save_config():
	var config = ConfigFile.new()
	for category in settings.keys():
		for key in settings[category]:
			config.set_value(category, key, settings[category][key])
	
	#save config
	config.save("user://settings.cfg")
