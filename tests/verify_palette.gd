extends SceneTree

func _init() -> void:
	call_deferred(&"_run_tests")

func _run_tests() -> void:
	var failed := 0
	var palette := load("res://palette.png") as Texture2D
	if palette == null or palette.get_width() != 32 or palette.get_height() != 1:
		printerr("palette.png 应为 32×1 色板")
		failed += 1

	var shader := load("res://palette.gdshader") as Shader
	if shader == null:
		printerr("无法加载色板后处理 shader")
		failed += 1
		quit(failed)
		return

	var packed_scene := load("res://main.tscn") as PackedScene
	if packed_scene == null:
		printerr("无法加载主场景")
		failed += 1
		quit(failed)
		return
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	var game_view := scene.get_node("GameView") as SubViewportContainer
	if game_view == null:
		printerr("找不到 GameView")
		failed += 1
		scene.queue_free()
		quit(failed)
		return
	var material := game_view.material as ShaderMaterial
	if material == null or material.shader != shader:
		printerr("GameView 应挂载色板后处理材质")
		failed += 1
	else:
		var material_palette := material.get_shader_parameter("palette") as Texture2D
		if material_palette == null or material_palette.resource_path != palette.resource_path:
			printerr("色板后处理材质应使用 palette.png")
			failed += 1
	if failed == 0:
		print("[verify_palette] 全部通过")
	scene.queue_free()
	quit(failed)
