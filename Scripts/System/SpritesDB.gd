extends Node
class_name SpritesDB

var DB:Dictionary = {
	"Players":{
		"Idle" : {
			"North": preload("res://Graphics/textures/Player/Idle/Player_N.png"),
			"NorthEast": preload("res://Graphics/textures/Player/Idle/Player_NE.png"),
			"East": preload("res://Graphics/textures/Player/Idle/Player_E.png"),
			"SouthEast": preload("res://Graphics/textures/Player/Idle/Player_SE.png"),
			"South": preload("res://Graphics/textures/Player/Idle/Player_S.png"),
			"SouthWest": preload("res://Graphics/textures/Player/Idle/Player_SW.png"),
			"West": preload("res://Graphics/textures/Player/Idle/Player_W.png"),
			"NorthWest": preload("res://Graphics/textures/Player/Idle/Player_NW.png")
		},
		"Walk" : {
			"North": preload("res://Graphics/textures/Player/Walk/Walk_N.gif"),
			"NorthEast": preload("res://Graphics/textures/Player/Walk/Walk_NE.gif"),
			"East": preload("res://Graphics/textures/Player/Walk/Walk_E.gif"),
			"SouthEast": preload("res://Graphics/textures/Player/Walk/Walk_SE.gif"),
			"South": preload("res://Graphics/textures/Player/Walk/Walk_S.gif"),
			"SouthWest": preload("res://Graphics/textures/Player/Walk/Walk_SW.gif"),
			"West": preload("res://Graphics/textures/Player/Walk/Walk_W.gif"),
			"NorthWest": preload("res://Graphics/textures/Player/Walk/Walk_NW.gif")
		}
	},
	"Guard": {
		"Idle" : {
			"North": preload("res://Graphics/textures/Guard/Idle/Guard_N.png"),
			"NorthEast": preload("res://Graphics/textures/Guard/Idle/Guard_NE.png"),
			"East": preload("res://Graphics/textures/Guard/Idle/Guard_E.png"),
			"SouthEast": preload("res://Graphics/textures/Guard/Idle/Guard_SE.png"),
			"South": preload("res://Graphics/textures/Guard/Idle/Guard_S.png"),
			"SouthWest": preload("res://Graphics/textures/Guard/Idle/Guard_SW.png"),
			"West": preload("res://Graphics/textures/Guard/Idle/Guard_W.png"),
			"NorthWest": preload("res://Graphics/textures/Guard/Idle/Guard_NW.png")
		},
		"Walk" : {
			"North": Texture.new(),
			"NorthEast": Texture.new(),
			"East": Texture.new(),
			"SouthEast": Texture.new(),
			"South": Texture.new(),
			"SouthWest": Texture.new(),
			"West": Texture.new(),
			"NorthWest": Texture.new()
		}
	}
} 
