extends Node3D

@onready var _viewport = $Viewport
@onready var _cam = $Viewport/Camera3D

@export var light_detect_interval : float = 0.25
var _last_time_since_detect : float = 0.0

var _player : Player = null

func _ready() -> void:
	_player = get_parent()


func _get_time() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(_delta) -> void:
	var new_pos = _player.global_transform.origin + Vector3.UP * 0.5
	
	_cam.global_transform.origin = new_pos
	if OS.has_feature("dedicated_server"):
		return
	if _last_time_since_detect + light_detect_interval > _get_time() and _last_time_since_detect != 0.0:
		return
		
	var level = get_light_level()
	if _player.Inputs.state == _player.Inputs.States.STATE_CROUCHING and not _player.lantern_lit:
		level = level / 1.2
	if _player.Inputs.state == _player.Inputs.States.STATE_CRAWLING and not _player.lantern_lit:
		level = level / 1.5
	_player.light_level = level
	_last_time_since_detect = _get_time()


func get_light_level() -> float:
	var texture = _viewport.get_texture()
	
	var color = get_average_color(texture)
	
	return color.get_luminance()
	
func get_average_color(texture: ViewportTexture) -> Color:
	var image = texture.get_image() # Get the Image of the input texture
	image.resize(1, 1, Image.INTERPOLATE_LANCZOS) # Resize the image to one pixel
	return image.get_pixel(0, 0) # Read the color of that pixel
