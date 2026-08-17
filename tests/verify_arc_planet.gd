extends SceneTree
## 头无模式验证：2D 圆弧星球常量、角度 wrap、侧视贴图、无旧伪 3D 残留、
## 场景结构 / 地物数量 / Surface.rotation ≈ -player_angle / 玩家在弧顶 / InputMap。
## 用法：
##   /workspace/.engine/.engine --headless --path /workspace \
##     --script res://tests/verify_arc_planet.gd

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var failed := 0
	failed += _check_constants()
	failed += _check_angle_wrap()
	failed += _check_pixel_art()
	failed += _check_no_legacy()
	failed += _check_input_map()
	failed += await _check_scene_and_mechanics()
	if failed == 0:
		print("[verify_arc_planet] 全部通过")
		quit(0)
	else:
		printerr("[verify_arc_planet] 失败项数：%d" % failed)
		quit(1)

func _check_constants() -> int:
	var failed := 0
	if WorldConstants.VOLCANO_COUNT != 3:
		printerr("VOLCANO_COUNT 应为 3，实际 %d" % WorldConstants.VOLCANO_COUNT)
		failed += 1
	if WorldConstants.ROSE_COUNT != 1:
		printerr("ROSE_COUNT 应为 1，实际 %d" % WorldConstants.ROSE_COUNT)
		failed += 1
	if WorldConstants.BAOBAB_COUNT < 10:
		printerr("BAOBAB_COUNT 过少：%d" % WorldConstants.BAOBAB_COUNT)
		failed += 1
	# 相对旧大圆（720）必须明显缩小，落在小星球目标区间
	const OLD_PLANET_RADIUS := 720.0
	if WorldConstants.PLANET_RADIUS >= OLD_PLANET_RADIUS * 0.5:
		printerr(
			"PLANET_RADIUS 应远小于旧值 %.0f，实际 %s"
			% [OLD_PLANET_RADIUS, WorldConstants.PLANET_RADIUS]
		)
		failed += 1
	if WorldConstants.PLANET_RADIUS < 100.0 or WorldConstants.PLANET_RADIUS > 280.0:
		printerr("PLANET_RADIUS 应约在 200~240（允许 100~280）：%s" % WorldConstants.PLANET_RADIUS)
		failed += 1
	# 弧顶须偏下，屏幕底部只露浅弧
	if WorldConstants.APEX_Y_RATIO < 0.80 or WorldConstants.APEX_Y_RATIO >= 1.0:
		printerr("APEX_Y_RATIO 应偏下（约 0.85~0.92）：%s" % WorldConstants.APEX_Y_RATIO)
		failed += 1
	# 地物/玩家精灵须明显大于旧大圆时代的尺寸
	if WorldConstants.SPRITE_VOLCANO <= 64:
		printerr("SPRITE_VOLCANO 应明显大于旧值 64，实际 %d" % WorldConstants.SPRITE_VOLCANO)
		failed += 1
	if WorldConstants.SPRITE_BAOBAB <= 48:
		printerr("SPRITE_BAOBAB 应明显大于旧值 48，实际 %d" % WorldConstants.SPRITE_BAOBAB)
		failed += 1
	if WorldConstants.SPRITE_ROSE <= 32:
		printerr("SPRITE_ROSE 应明显大于旧值 32，实际 %d" % WorldConstants.SPRITE_ROSE)
		failed += 1
	if WorldConstants.SPRITE_PLAYER_W <= 22 or WorldConstants.SPRITE_PLAYER_H <= 32:
		printerr(
			"SPRITE_PLAYER 应明显加大，实际 %dx%d"
			% [WorldConstants.SPRITE_PLAYER_W, WorldConstants.SPRITE_PLAYER_H]
		)
		failed += 1
	# 旧伪 3D 常量不得残留在源码中
	var const_src := FileAccess.get_file_as_string("res://scripts/world_constants.gd")
	for legacy in [
		"TILE_SIZE", "MAP_TILES", "WORLD_PIXELS", "VIEWPORT_PIXELS",
		"LAYER_COUNT", "ROSE_LAYER_COUNT", "STACK_OUTWARD_EPSILON", "STACK_LEAN",
	]:
		if const_src.find(legacy) >= 0:
			printerr("world_constants.gd 仍含旧符号：%s" % legacy)
			failed += 1
	print("  常量检查 OK（小半径 / 弧顶偏下 / 大地物精灵 / 地物数量）")
	return failed

func _check_angle_wrap() -> int:
	var failed := 0
	var a := fposmod(TAU + 0.3, TAU)
	if not is_equal_approx(a, 0.3):
		printerr("正角 wrap 失败：%s" % a)
		failed += 1
	a = fposmod(-0.4, TAU)
	if not is_equal_approx(a, TAU - 0.4):
		printerr("负角 wrap 失败：%s" % a)
		failed += 1
	a = fposmod(3.0 * TAU + 1.2, TAU)
	if not is_equal_approx(a, 1.2):
		printerr("多圈 wrap 失败：%s" % a)
		failed += 1
	print("  角度 fposmod wrap OK")
	return failed

func _check_pixel_art() -> int:
	var failed := 0
	var sand := PixelArt.make_sand_tile(16)
	if sand.get_width() != 16 or sand.get_height() != 16:
		printerr("沙地贴图像素尺寸错误")
		failed += 1
	var volcano := PixelArt.make_volcano_sprite(WorldConstants.SPRITE_VOLCANO)
	var baobab := PixelArt.make_baobab_sprite(WorldConstants.SPRITE_BAOBAB)
	var rose := PixelArt.make_rose_sprite(WorldConstants.SPRITE_ROSE)
	var prince := PixelArt.make_player_sprite(
		WorldConstants.SPRITE_PLAYER_W, WorldConstants.SPRITE_PLAYER_H
	)
	if volcano == null or baobab == null or rose == null or prince == null:
		printerr("程序生成贴图失败")
		failed += 1
	if volcano.get_width() < 16 or baobab.get_width() < 16 or rose.get_width() < 8:
		printerr("侧视贴图尺寸过小")
		failed += 1
	# 旧 stacked 切片 API 不得存在
	var art_src := FileAccess.get_file_as_string("res://scripts/pixel_art.gd")
	for forbidden in ["make_volcano_layers", "make_baobab_layers", "make_rose_layers"]:
		if art_src.find(forbidden) >= 0:
			printerr("PixelArt 仍含 %s" % forbidden)
			failed += 1
	print("  程序生成侧视贴图 OK")
	return failed

func _check_no_legacy() -> int:
	var failed := 0
	for path in [
		"res://shaders/sphere_fisheye.gdshader",
		"res://scripts/stacked_prop.gd",
		"res://scripts/world_generator.gd",
	]:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			printerr("旧文件仍存在：%s" % path)
			failed += 1
	print("  无 sphere_fisheye / StackedProp 残留 OK")
	return failed

func _check_input_map() -> int:
	var failed := 0
	InputSetup.ensure_move_actions()
	for action in InputSetup.ACTIONS:
		if not InputMap.has_action(action):
			printerr("InputMap 缺少动作：%s" % action)
			failed += 1
			continue
		if InputMap.action_get_events(action).is_empty():
			printerr("动作 %s 没有任何按键事件" % action)
			failed += 1
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

func _check_scene_and_mechanics() -> int:
	var failed := 0
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		printerr("无法加载 scenes/main.tscn")
		return 1
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	for action in InputSetup.ACTIONS:
		if not InputMap.has_action(action):
			printerr("场景加载后缺少 InputMap 动作：%s" % action)
			failed += 1

	# 不得再有 SubViewport / PlanetView / ShaderMaterial
	if scene.get_node_or_null("WorldHost") != null:
		printerr("旧 WorldHost/SubViewport 结构仍存在")
		failed += 1
	if scene.get_node_or_null("PlanetView") != null:
		printerr("旧 PlanetView ColorRect 仍存在")
		failed += 1

	var planet: Planet = scene.get_node_or_null("Planet") as Planet
	var player: Player = scene.get_node_or_null("Player") as Player
	if planet == null:
		printerr("找不到 Planet")
		failed += 1
	if player == null:
		printerr("找不到 Player")
		failed += 1

	if planet != null:
		if planet.volcano_angles.size() != 3:
			printerr("火山数量应为 3，实际 %d" % planet.volcano_angles.size())
			failed += 1
		if planet.baobab_angles.size() != WorldConstants.BAOBAB_COUNT:
			printerr(
				"猴面包树数量应为 %d，实际 %d"
				% [WorldConstants.BAOBAB_COUNT, planet.baobab_angles.size()]
			)
			failed += 1
		var rose_count := 0
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.ROSE:
				rose_count += 1
		if rose_count != 1:
			printerr("玫瑰数量应为 1，实际 %d" % rose_count)
			failed += 1
		var expected_props: int = (
			WorldConstants.ROSE_COUNT + WorldConstants.VOLCANO_COUNT + WorldConstants.BAOBAB_COUNT
		)
		if planet.surface_props.size() != expected_props:
			printerr(
				"地表地物总数应为 %d，实际 %d"
				% [expected_props, planet.surface_props.size()]
			)
			failed += 1
		var surface: Node2D = planet.get_node_or_null("Surface") as Node2D
		if surface == null:
			printerr("找不到 Surface")
			failed += 1
		var body: Node2D = planet.get_node_or_null("Body") as Node2D
		if body == null:
			printerr("找不到 Body")
			failed += 1

	if planet != null and player != null:
		player.planet = planet
		# 改角后立刻同步：Body / Surface.rotation == -player_angle，玩家在弧顶
		player.set_angle_and_sync(0.75)
		# 同帧即可断言，无需等下一帧
		var surface2: Node2D = planet.get_node("Surface") as Node2D
		var body2: Node2D = planet.get_node("Body") as Node2D
		if not is_equal_approx(surface2.rotation, -player.angle):
			printerr(
				"Surface.rotation 应为 %s，实际 %s"
				% [-player.angle, surface2.rotation]
			)
			failed += 1
		if not is_equal_approx(body2.rotation, -player.angle):
			printerr(
				"Body.rotation 应为 %s，实际 %s（本体须随星球转）"
				% [-player.angle, body2.rotation]
			)
			failed += 1
		if not is_equal_approx(body2.rotation, surface2.rotation):
			printerr("Body 与 Surface 旋转应一致")
			failed += 1

		var apex: Vector2 = planet.apex_global_position()
		if player.global_position.distance_to(apex) > 0.5:
			printerr(
				"玩家应在弧顶 %s，实际 %s"
				% [apex, player.global_position]
			)
			failed += 1

		# 再测负角 wrap（同帧）
		player.set_angle_and_sync(fposmod(-0.2, TAU))
		if not is_equal_approx(surface2.rotation, -player.angle):
			printerr("负角时 Surface.rotation 不同步")
			failed += 1
		if not is_equal_approx(body2.rotation, -player.angle):
			printerr("负角时 Body.rotation 不同步")
			failed += 1

		# 弧顶相对球心应在正上方
		apex = planet.apex_global_position()
		var up: Vector2 = apex - planet.global_position
		if absf(up.x) > 0.5 or up.y >= 0.0:
			printerr("弧顶应在球心正上方，实际偏移 %s" % up)
			failed += 1
		if not is_equal_approx(up.length(), planet.planet_radius):
			printerr(
				"弧顶距离应等于半径 %s，实际 %s"
				% [planet.planet_radius, up.length()]
			)
			failed += 1

		# 精灵随半径相对基准缩放，并计入 PLAYER_SCALE / PROP_SCALE
		var expected_player: float = (
			planet.planet_radius / WorldConstants.PLANET_RADIUS * WorldConstants.PLAYER_SCALE
		)
		if not is_equal_approx(player.scale.x, expected_player):
			printerr(
				"玩家 scale 应为 %s，实际 %s"
				% [expected_player, player.scale.x]
			)
			failed += 1
		if not planet.surface_props.is_empty():
			var expected_prop: float = (
				planet.planet_radius / WorldConstants.PLANET_RADIUS * WorldConstants.PROP_SCALE
			)
			var prop_scale: float = planet.surface_props[0].scale.x
			if not is_equal_approx(prop_scale, expected_prop):
				printerr(
					"地物 scale 应为 %s，实际 %s"
					% [expected_prop, prop_scale]
				)
				failed += 1

		# 弧顶偏下：相对视口应靠近底部（浅露地表）
		var vp_h: float = scene.get_viewport_rect().size.y
		if vp_h > 1.0:
			var apex_ratio: float = apex.y / vp_h
			if apex_ratio < 0.75:
				printerr("弧顶 Y 比例应偏下（≥0.75），实际 %s" % apex_ratio)
				failed += 1
			# 球心应在屏幕底边之外或极近底边，只露浅弧
			if planet.global_position.y < vp_h * 0.95:
				printerr(
					"球心应靠近/低于屏幕底边以浅露弧面，实际 y=%s / vh=%s"
					% [planet.global_position.y, vp_h]
				)
				failed += 1

		# 模拟缩小半径后比例仍正确
		var half_r: float = WorldConstants.PLANET_RADIUS * 0.5
		planet.apply_layout(planet.global_position, half_r)
		player.set_planet_radius(half_r)
		player.place_at_apex(planet.apex_global_position())
		var half_player: float = 0.5 * WorldConstants.PLAYER_SCALE
		var half_prop: float = 0.5 * WorldConstants.PROP_SCALE
		if not is_equal_approx(player.scale.x, half_player):
			printerr("半半径时玩家 scale 应为 %s，实际 %s" % [half_player, player.scale.x])
			failed += 1
		if not is_equal_approx(planet.surface_props[0].scale.x, half_prop):
			printerr(
				"半半径时地物 scale 应为 %s，实际 %s"
				% [half_prop, planet.surface_props[0].scale.x]
			)
			failed += 1

	print("  场景与圆弧力学 OK")
	scene.queue_free()
	await process_frame
	return failed
