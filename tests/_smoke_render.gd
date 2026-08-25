extends SceneTree


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var rect := ColorRect.new()
	rect.color = Color(0.2, 0.6, 0.9, 1.0)
	rect.size = Vector2(256, 224)
	root.add_child(rect)
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png("/tmp/smoke_render.png")
	print("SMOKE_OK size=%s pixel=%s" % [image.get_size(), image.get_pixel(10, 10)])
	quit(0)
