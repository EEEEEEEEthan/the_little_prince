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

	var scene := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var game_view := scene.get_node("GameView") as SubViewportContainer
	var material := game_view.material as ShaderMaterial
	if material == null or material.shader != shader:
		printerr("GameView 应挂载色板后处理材质")
		failed += 1
	elif material.get_shader_parameter("palette") != palette:
		printerr("色板后处理材质应使用 palette.png")
		failed += 1
	if failed == 0:
		print("[verify_palette] 全部通过")
	scene.queue_free()
	quit(failed)
