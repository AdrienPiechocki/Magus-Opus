@tool
extends SubViewport

var axes:Array = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
@export var _name:String
@export var animation_name:String

@export_tool_button("Generate Sprite")
var generate_sprite = func():
	var model = $Model.get_child(0)
	var animator:AnimationPlayer = null
	if model.has_node("AnimationPlayer"):
		animator = model.get_node("AnimationPlayer")
		if animation_name in animator.get_animation_list():
			animator.current_animation = animation_name
			var timelist:Array = []
			for i in rangef(0, animator.current_animation_length, 0.2):
				timelist.append(i)
			var angle = 0.0
			var format = get_texture().get_image().get_format()
			var result = Image.create_empty(size.x, size.y, false, format)
			for i in axes:
				model.rotation.y = angle
				for t in timelist:
					animator.seek(t, true)
					await RenderingServer.frame_post_draw
					var image = get_texture().get_image()
					result = image
					result.save_png("user://"+_name+"_"+str(t)+"_"+i+".png")
					angle += TAU / 8
		print("DONE")


func rangef(start: float, end: float, step: float):
	var res = Array()
	var i = start
	while i < end:
		res.push_back(i)
		i += step
	return res
