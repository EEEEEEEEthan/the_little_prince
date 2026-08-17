extends SceneTree
## 头无模式验证脚本：检查世界常量、环面 wrap、场景可加载、地物数量。
## 用法：
##   /workspace/.engine/.engine --headless --path /workspace \
##     --script res://tests/verify_pseudo_planet.gd

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var failed := 0
	failed += _check_constants()
	failed += _check_wrap_math()
	failed += _check_pixel_art()
	failed += await _check_scene_and_world()
	if failed == 0:
		print("[verify_pseudo_planet] 全部通过")
		quit(0)
	else:
		printerr("[verify_pseudo_planet] 失败项数：%d" % failed)
		quit(1)

func _check_constants() -> int:
	var failed := 0
	if WorldConstants.TILE_SIZE != 16:
		printerr("TILE_SIZE 应为 16，实际 %d" % WorldConstants.TILE_SIZE)
		failed += 1
	if WorldConstants.MAP_TILES != 32:
		printerr("MAP_TILES 应为 32，实际 %d" % WorldConstants.MAP_TILES)
		failed += 1
	if WorldConstants.WORLD_PIXELS != 512:
		printerr("WORLD_PIXELS 应为 512，实际 %d" % WorldConstants.WORLD_PIXELS)
		failed += 1
	if WorldConstants.VOLCANO_COUNT != 3:
		printerr("VOLCANO_COUNT 应为 3，实际 %d" % WorldConstants.VOLCANO_COUNT)
		failed += 1
	if WorldConstants.ROSE_COUNT != 1:
		printerr("ROSE_COUNT 应为 1，实际 %d" % WorldConstants.ROSE_COUNT)
		failed += 1
	if WorldConstants.BAOBAB_COUNT < 10:
		printerr("BAOBAB_COUNT 过少：%d" % WorldConstants.BAOBAB_COUNT)
		failed += 1
	print("  常量检查 OK（16×16 格，32×32 地图，512×512 世界）")
	return failed

func _check_wrap_math() -> int:
	var failed := 0
	var w := float(WorldConstants.WORLD_PIXELS)
	var x := fposmod(w + 12.5, w)
	if not is_equal_approx(x, 12.5):
		printerr("右边界 wrap 失败：%s" % x)
		failed += 1
	x = fposmod(-3.0, w)
	if not is_equal_approx(x, w - 3.0):
		printerr("左边界 wrap 失败：%s" % x)
		failed += 1
	var y := fposmod(w + 1.0, w)
	if not is_equal_approx(y, 1.0):
		printerr("下边界 wrap 失败：%s" % y)
		failed += 1
	y = fposmod(-0.5, w)
	if not is_equal_approx(y, w - 0.5):
		printerr("上边界 wrap 失败：%s" % y)
		failed += 1
	print("  环面 wrap 数学 OK")
	return failed

func _check_pixel_art() -> int:
	var failed := 0
	var sand := PixelArt.make_sand_tile(WorldConstants.TILE_SIZE)
	if sand.get_width() != 16 or sand.get_height() != 16:
		printerr("沙地贴图像素尺寸错误")
		failed += 1
	var volcano := PixelArt.make_volcano_sprite(36)
	var baobab := PixelArt.make_baobab_sprite(28)
	var rose := PixelArt.make_rose_sprite(18)
	var prince := PixelArt.make_player_sprite(14, 20)
	if volcano == null or baobab == null or rose == null or prince == null:
		printerr("程序生成贴图失败")
		failed += 1
	print("  程序生成贴图 OK")
	return failed

func _check_scene_and_world() -> int:
	var failed := 0
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		printerr("无法加载 scenes/main.tscn")
		return 1
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var world: WorldGenerator = scene.get_node_or_null("WorldHost/WorldViewport/PlanetWorld") as WorldGenerator
	if world == null:
		printerr("找不到 PlanetWorld 节点")
		failed += 1
	else:
		if world.volcano_tiles.size() != 3:
			printerr("火山数量应为 3，实际 %d" % world.volcano_tiles.size())
			failed += 1
		if world.baobab_tiles.size() != WorldConstants.BAOBAB_COUNT:
			printerr(
				"猴面包树数量应为 %d，实际 %d"
				% [WorldConstants.BAOBAB_COUNT, world.baobab_tiles.size()]
			)
			failed += 1
		var ground: TileMapLayer = world.get_node("Ground") as TileMapLayer
		if ground == null or ground.tile_set == null:
			printerr("Ground TileMapLayer / TileSet 未就绪")
			failed += 1
		elif ground.tile_set.tile_size != Vector2i(16, 16):
			printerr("TileSet.tile_size 应为 (16,16)，实际 %s" % ground.tile_set.tile_size)
			failed += 1
		else:
			for cell in [Vector2i(0, 0), Vector2i(31, 31), Vector2i(16, 16)]:
				if ground.get_cell_source_id(cell) == -1:
					printerr("格子 %s 未绘制" % cell)
					failed += 1

	var player: Player = scene.get_node_or_null("WorldHost/WorldViewport/PlanetWorld/Player") as Player
	if player == null:
		printerr("找不到 Player")
		failed += 1
	else:
		player.world_pixel_size = float(WorldConstants.WORLD_PIXELS)
		player.global_position = Vector2(float(WorldConstants.WORLD_PIXELS) + 5.0, -2.0)
		player._wrap_around()
		if not is_equal_approx(player.global_position.x, 5.0):
			printerr("玩家 X wrap 失败：%s" % player.global_position.x)
			failed += 1
		if not is_equal_approx(player.global_position.y, float(WorldConstants.WORLD_PIXELS) - 2.0):
			printerr("玩家 Y wrap 失败：%s" % player.global_position.y)
			failed += 1

	var viewport: SubViewport = scene.get_node_or_null("WorldHost/WorldViewport") as SubViewport
	if viewport == null or viewport.size != Vector2i(512, 512):
		printerr("SubViewport 尺寸应为 512×512，实际 %s" % (viewport.size if viewport else "null"))
		failed += 1

	print("  场景与世界生成 OK")
	scene.queue_free()
	await process_frame
	return failed
