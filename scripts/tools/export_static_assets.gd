extends SceneTree
## 一次性 / 可重复：用 PixelArt 算法生成静态 PNG 到 assets/。
## 用法：
##   /workspace/.engine/.engine --headless --path /workspace \
##     --script res://scripts/tools/export_static_assets.gd

func _init() -> void:
	call_deferred("_export")

func _export() -> void:
	var err := 0
	err += _save(
		PixelArt.build_player_sprite(WorldConstants.SPRITE_PLAYER_W, WorldConstants.SPRITE_PLAYER_H),
		"res://assets/sprites/prince.png"
	)
	err += _save(
		PixelArt.build_rose_sprite(WorldConstants.SPRITE_ROSE),
		"res://assets/sprites/rose.png"
	)
	err += _save(
		PixelArt.build_volcano_sprite(WorldConstants.SPRITE_VOLCANO),
		"res://assets/sprites/volcano.png"
	)
	err += _save(
		PixelArt.build_baobab_sprite(WorldConstants.SPRITE_BAOBAB),
		"res://assets/sprites/baobab.png"
	)
	err += _save(
		PixelArt.build_planet_body(WorldConstants.PLANET_RADIUS),
		"res://assets/planet/body.png"
	)
	err += _save(
		PixelArt.build_starfield(WorldConstants.INTERNAL_WIDTH, WorldConstants.INTERNAL_HEIGHT),
		"res://assets/bg/starfield.png"
	)
	if err == 0:
		print("[export_static_assets] 全部 PNG 已写入 assets/")
		quit(0)
	else:
		printerr("[export_static_assets] 失败项数：%d" % err)
		quit(1)

func _save(img: Image, path: String) -> int:
	if img == null:
		printerr("生成失败：%s" % path)
		return 1
	var abs_path: String = ProjectSettings.globalize_path(path)
	var dir_path: String = abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	var save_err: Error = img.save_png(abs_path)
	if save_err != OK:
		printerr("保存失败 %s：错误码 %d" % [path, save_err])
		return 1
	print("  已写入 %s（%dx%d）" % [path, img.get_width(), img.get_height()])
	return 0
