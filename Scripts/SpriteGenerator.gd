@tool
extends SubViewport

@export var axes:int = 8

@export_tool_button("Generate Sprite")
var generate_sprite = func():
	var model = $Adventurer
	var angle = 0.0
	var format = get_texture().get_image().get_format()
	var result = Image.create_empty(size.x, size.y, false, format)
	for i in axes:
		model.rotation.y = angle
		await RenderingServer.frame_post_draw
		var image = get_texture().get_image()
		result = image
		result.save_png("/home/adrien/sprites"+str(i+1)+".png")
		angle += TAU / 8
