extends SceneTree
## 用 PixelArt 算法生成静态 PNG 到 player/ 与 planet/。
## 用法：
##   ./.engine/.engine.exe --headless --path . --script res://tools/export_static_assets.gd

func _init() -> void:
	call_deferred(&"_export")

func _export() -> void:
	var failed := 0
	failed += _save(
		PixelArt.build_player_sprite(
			WorldConstants.PLAYER_SPRITE_WIDTH, WorldConstants.PLAYER_SPRITE_HEIGHT
		),
		"res://player/prince.png",
	)
	failed += _save(
		PixelArt.build_rose_sprite(WorldConstants.ROSE_SPRITE_SIZE),
		"res://planet/rose.png",
	)
	failed += _save(
		PixelArt.build_volcano_sprite(WorldConstants.VOLCANO_SPRITE_SIZE),
		"res://planet/volcano.png",
	)
	failed += _save(
		PixelArt.build_baobab_sprite(WorldConstants.BAOBAB_SPRITE_SIZE),
		"res://planet/baobab.png",
	)
	failed += _save(
		PixelArt.build_planet_body(WorldConstants.PLANET_RADIUS),
		"res://planet/body.png",
	)
	failed += _save(
		PixelArt.build_starfield(WorldConstants.STARFIELD_SIZE, WorldConstants.STARFIELD_SIZE),
		"res://planet/starfield.png",
	)
	if failed == 0:
		print("[export_static_assets] 全部 PNG 已写入 player/ 与 planet/")
		quit(0)
	else:
		printerr("[export_static_assets] 失败项数：%d" % failed)
		quit(1)

func _save(image: Image, path: String) -> int:
	if image == null:
		printerr("生成失败：%s" % path)
		return 1
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error != OK:
		printerr("保存失败 %s：错误码 %d" % [path, error])
		return 1
	print("  已写入 %s（%dx%d）" % [path, image.get_width(), image.get_height()])
	return 0
