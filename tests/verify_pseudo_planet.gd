extends SceneTree
## 头无模式验证脚本：检查世界常量、环面 wrap、场景可加载、地物数量、
## InputMap 动作、shader 无边缘辉光。
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
	failed += _check_stacked_orientation()
	failed += _check_input_map()
	failed += _check_shader_no_rim()
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
	if WorldConstants.ROSE_LAYER_COUNT < 3:
		printerr("ROSE_LAYER_COUNT 过少：%d" % WorldConstants.ROSE_LAYER_COUNT)
		failed += 1
	if WorldConstants.BAOBAB_LAYER_COUNT < 3:
		printerr("BAOBAB_LAYER_COUNT 过少：%d" % WorldConstants.BAOBAB_LAYER_COUNT)
		failed += 1
	if WorldConstants.VOLCANO_LAYER_COUNT < 3:
		printerr("VOLCANO_LAYER_COUNT 过少：%d" % WorldConstants.VOLCANO_LAYER_COUNT)
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

	# Stacked 切片：多层、非空、底→顶数量合理
	failed += _assert_layers(
		PixelArt.make_volcano_layers(36),
		WorldConstants.VOLCANO_LAYER_COUNT,
		"火山"
	)
	failed += _assert_layers(
		PixelArt.make_baobab_layers(28),
		WorldConstants.BAOBAB_LAYER_COUNT,
		"猴面包树"
	)
	failed += _assert_layers(
		PixelArt.make_rose_layers(18),
		WorldConstants.ROSE_LAYER_COUNT,
		"玫瑰"
	)
	print("  程序生成贴图 OK（含 stacked 切片）")
	return failed

func _assert_layers(layers: Array[Texture2D], expected: int, label: String) -> int:
	if layers.size() != expected:
		printerr("%s 切片层数应为 %d，实际 %d" % [label, expected, layers.size()])
		return 1
	if layers.is_empty():
		printerr("%s 切片为空" % label)
		return 1
	for i in layers.size():
		if layers[i] == null:
			printerr("%s 第 %d 层纹理为空" % [label, i])
			return 1
		if layers[i].get_width() < 4 or layers[i].get_height() < 4:
			printerr("%s 第 %d 层尺寸过小" % [label, i])
			return 1
	return 0

func _check_stacked_orientation() -> int:
	## 经典 stacking：切片不旋转，只沿 outward 做位置偏移（倾斜堆叠）
	var failed := 0
	var prop := StackedProp.new()
	prop.world_pixel_size = float(WorldConstants.WORLD_PIXELS)
	var layers: Array[Texture2D] = PixelArt.make_rose_layers(12, 3)
	prop.configure(layers, 1.0, Vector2.ZERO, Vector2(100, 200), float(WorldConstants.WORLD_PIXELS))

	if prop._wrap_roots.size() != 9:
		printerr("环绕副本数应为 9，实际 %d" % prop._wrap_roots.size())
		failed += 1
		prop.free()
		return failed

	# --- 下方视角：outward≈+Y，高层 position.y > 低层，且 rotation≈0 ---
	var player_below := Vector2(100, 100)
	var anchor := Vector2(100, 200)
	var delta := prop.torus_delta(anchor, player_below)
	if delta.y <= 0.0 or absf(delta.x) > 1.0:
		printerr("torus_delta 下方方向错误：%s" % delta)
		failed += 1

	prop.update_toward(player_below)
	var main_root: Node2D = prop._wrap_roots[4]
	if not is_zero_approx(main_root.rotation):
		printerr("下方视角 root 不应旋转：%s" % main_root.rotation)
		failed += 1
	var bot: Sprite2D = prop._wrap_layers[4][0]
	var mid: Sprite2D = prop._wrap_layers[4][1]
	var top: Sprite2D = prop._wrap_layers[4][2]
	for spr in [bot, mid, top]:
		if not is_zero_approx(spr.rotation):
			printerr("切片不应旋转：%s" % spr.rotation)
			failed += 1
			break
	if not (top.position.y > mid.position.y and mid.position.y > bot.position.y):
		printerr(
			"下方视角高层应沿 +Y 偏移：bot=%s mid=%s top=%s"
			% [bot.position, mid.position, top.position]
		)
		failed += 1

	# --- 右侧视角：outward≈+X，高层 position.x > 低层 ---
	var player_left := Vector2(50, 200)
	prop.update_toward(player_left)
	bot = prop._wrap_layers[4][0]
	mid = prop._wrap_layers[4][1]
	top = prop._wrap_layers[4][2]
	for spr2 in [bot, mid, top]:
		if not is_zero_approx(spr2.rotation):
			printerr("右侧视角切片不应旋转：%s" % spr2.rotation)
			failed += 1
			break
	if not (top.position.x > mid.position.x and mid.position.x > bot.position.x):
		printerr(
			"右侧视角高层应沿 +X 偏移：bot=%s mid=%s top=%s"
			% [bot.position, mid.position, top.position]
		)
		failed += 1

	prop.free()
	if failed == 0:
		print("  StackedProp 倾斜堆叠 / 不旋转 OK")
	return failed

func _check_input_map() -> int:
	var failed := 0
	# 先走运行时注册（与游戏启动路径一致），再断言四个动作存在
	InputSetup.ensure_move_actions()
	for action in InputSetup.ACTIONS:
		if not InputMap.has_action(action):
			printerr("InputMap 缺少动作：%s" % action)
			failed += 1
			continue
		var events := InputMap.action_get_events(action)
		if events.is_empty():
			printerr("动作 %s 没有任何按键事件" % action)
			failed += 1
	# 再验证：即使清空后重新 ensure，也能恢复
	for action in InputSetup.ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	InputSetup._ensured = false
	InputSetup.ensure_move_actions()
	for action in InputSetup.ACTIONS:
		if not InputMap.has_action(action):
			printerr("运行时重新注册失败：%s" % action)
			failed += 1
	print("  InputMap move_* 动作 OK")
	return failed

func _check_shader_no_rim() -> int:
	var failed := 0
	var path := "res://shaders/sphere_fisheye.gdshader"
	if not FileAccess.file_exists(path):
		printerr("找不到 shader：%s" % path)
		return 1
	var src := FileAccess.get_file_as_string(path)
	for forbidden in ["rim_glow", "rim_glow_color", "float rim"]:
		if src.find(forbidden) >= 0:
			printerr("shader 仍含边缘光相关内容：%s" % forbidden)
			failed += 1
	if src.find("view_size") < 0:
		printerr("shader 缺少 view_size uniform（正圆 aspect 所需）")
		failed += 1
	print("  shader 无 rim / 含 view_size OK")
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

	# 场景加载后四个 move_* 必须仍存在（main._ready / player._ready 会 ensure）
	for action in InputSetup.ACTIONS:
		if not InputMap.has_action(action):
			printerr("场景加载后缺少 InputMap 动作：%s" % action)
			failed += 1

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

		# Props 下应为 StackedProp（玫瑰+火山+猴面包），且层数合理
		var expected_props: int = (
			WorldConstants.ROSE_COUNT + WorldConstants.VOLCANO_COUNT + WorldConstants.BAOBAB_COUNT
		)
		if world.stacked_props.size() != expected_props:
			printerr(
				"StackedProp 数量应为 %d，实际 %d"
				% [expected_props, world.stacked_props.size()]
			)
			failed += 1
		var props_node: Node2D = world.get_node_or_null("Props") as Node2D
		if props_node == null:
			printerr("找不到 Props 节点")
			failed += 1
		else:
			var stacked_in_tree := 0
			for child in props_node.get_children():
				if child is StackedProp:
					stacked_in_tree += 1
					var sp: StackedProp = child
					if sp.layer_textures.size() < 3:
						printerr("StackedProp 层数过少：%d" % sp.layer_textures.size())
						failed += 1
					if sp._wrap_roots.size() != 9:
						printerr("StackedProp 环绕副本应为 9，实际 %d" % sp._wrap_roots.size())
						failed += 1
			if stacked_in_tree != expected_props:
				printerr(
					"Props 下 StackedProp 节点数应为 %d，实际 %d"
					% [expected_props, stacked_in_tree]
				)
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

	# 确认 PlanetView 材质已写入 view_size，且无 rim 参数
	var planet_view: ColorRect = scene.get_node_or_null("PlanetView") as ColorRect
	if planet_view == null:
		printerr("找不到 PlanetView")
		failed += 1
	else:
		var mat := planet_view.material as ShaderMaterial
		if mat == null:
			printerr("PlanetView 无 ShaderMaterial")
			failed += 1
		else:
			var vs: Variant = mat.get_shader_parameter("view_size")
			if typeof(vs) != TYPE_VECTOR2:
				printerr("view_size 未正确设置")
				failed += 1

	print("  场景与世界生成 OK")
	scene.queue_free()
	await process_frame
	return failed
