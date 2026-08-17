extends SceneTree
## 头无模式验证：256×224 SubViewport 像素视口、静态 assets、圆弧力学、无旧伪 3D 残留。
## 用法：
##   /workspace/.engine/.engine --headless --path /workspace \
##     --script res://tests/verify_arc_planet.gd

const VIEWPORT_PATH := "GameView/GameViewport"
const PLANET_PATH := "GameView/GameViewport/Planet"
const PLAYER_PATH := "GameView/GameViewport/Player"

const REQUIRED_ASSETS: Array[String] = [
	"res://assets/sprites/prince.png",
	"res://assets/sprites/rose.png",
	"res://assets/sprites/volcano.png",
	"res://assets/sprites/baobab.png",
	"res://assets/planet/body.png",
	"res://assets/bg/starfield.png",
]

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var failed := 0
	failed += _check_constants()
	failed += _check_angle_wrap()
	failed += _check_static_assets()
	failed += _check_pixel_art_export_api()
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
	if WorldConstants.INTERNAL_WIDTH != 256 or WorldConstants.INTERNAL_HEIGHT != 224:
		printerr(
			"内部视口应为 256×224，实际 %dx%d"
			% [WorldConstants.INTERNAL_WIDTH, WorldConstants.INTERNAL_HEIGHT]
		)
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
	# 内部坐标系半径：大于旧等比缩放约 51，落在建议区间 78~90
	if WorldConstants.PLANET_RADIUS < 78.0 or WorldConstants.PLANET_RADIUS > 90.0:
		printerr(
			"PLANET_RADIUS 应在 78~90（内部 256×224）：%s"
			% WorldConstants.PLANET_RADIUS
		)
		failed += 1
	# 弧顶须偏下，屏幕底部只露浅弧（地面不往上移）
	if WorldConstants.APEX_Y_RATIO < 0.80 or WorldConstants.APEX_Y_RATIO >= 1.0:
		printerr("APEX_Y_RATIO 应偏下（约 0.85~0.92）：%s" % WorldConstants.APEX_Y_RATIO)
		failed += 1
	# 像素风精灵尺寸相对半径 ~80 应协调（不宜再是 120/96）
	if WorldConstants.SPRITE_VOLCANO < 28 or WorldConstants.SPRITE_VOLCANO > 48:
		printerr("SPRITE_VOLCANO 应约 32~40，实际 %d" % WorldConstants.SPRITE_VOLCANO)
		failed += 1
	if WorldConstants.SPRITE_BAOBAB < 24 or WorldConstants.SPRITE_BAOBAB > 40:
		printerr("SPRITE_BAOBAB 应约 28~36，实际 %d" % WorldConstants.SPRITE_BAOBAB)
		failed += 1
	if WorldConstants.SPRITE_ROSE < 14 or WorldConstants.SPRITE_ROSE > 26:
		printerr("SPRITE_ROSE 应约 16~22，实际 %d" % WorldConstants.SPRITE_ROSE)
		failed += 1
	if (
		WorldConstants.SPRITE_PLAYER_W < 10 or WorldConstants.SPRITE_PLAYER_W > 16
		or WorldConstants.SPRITE_PLAYER_H < 14 or WorldConstants.SPRITE_PLAYER_H > 24
	):
		printerr(
			"SPRITE_PLAYER 应约 12×18，实际 %dx%d"
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
	print("  常量检查 OK（内部视口 / 半径 78~90 / 弧顶偏下 / 像素精灵）")
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

func _check_static_assets() -> int:
	var failed := 0
	for path in REQUIRED_ASSETS:
		if not FileAccess.file_exists(path):
			printerr("缺少静态资源：%s" % path)
			failed += 1
			continue
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			printerr("无法加载贴图：%s" % path)
			failed += 1
			continue
		if tex.get_width() < 8 or tex.get_height() < 8:
			printerr("贴图尺寸过小：%s（%dx%d）" % [path, tex.get_width(), tex.get_height()])
			failed += 1
	# 星野应对齐内部分辨率
	var star: Texture2D = load("res://assets/bg/starfield.png") as Texture2D
	if star != null:
		if star.get_width() != WorldConstants.INTERNAL_WIDTH or star.get_height() != WorldConstants.INTERNAL_HEIGHT:
			printerr(
				"starfield 应为 %dx%d，实际 %dx%d"
				% [
					WorldConstants.INTERNAL_WIDTH, WorldConstants.INTERNAL_HEIGHT,
					star.get_width(), star.get_height(),
				]
			)
			failed += 1
	# 星球圆盘直径应约等于 2 * PLANET_RADIUS
	var body: Texture2D = load("res://assets/planet/body.png") as Texture2D
	if body != null:
		var expected_d: int = int(ceil(WorldConstants.PLANET_RADIUS)) * 2
		if body.get_width() != expected_d or body.get_height() != expected_d:
			printerr(
				"body.png 应为 %dx%d，实际 %dx%d"
				% [expected_d, expected_d, body.get_width(), body.get_height()]
			)
			failed += 1
	# 精灵尺寸应对齐常量
	var checks: Array = [
		["res://assets/sprites/volcano.png", WorldConstants.SPRITE_VOLCANO, WorldConstants.SPRITE_VOLCANO],
		["res://assets/sprites/baobab.png", WorldConstants.SPRITE_BAOBAB, WorldConstants.SPRITE_BAOBAB],
		["res://assets/sprites/rose.png", WorldConstants.SPRITE_ROSE, WorldConstants.SPRITE_ROSE],
		["res://assets/sprites/prince.png", WorldConstants.SPRITE_PLAYER_W, WorldConstants.SPRITE_PLAYER_H],
	]
	for item in checks:
		var t: Texture2D = load(item[0]) as Texture2D
		if t == null:
			continue
		if t.get_width() != int(item[1]) or t.get_height() != int(item[2]):
			printerr(
				"%s 尺寸应为 %dx%d，实际 %dx%d"
				% [item[0], item[1], item[2], t.get_width(), t.get_height()]
			)
			failed += 1
	print("  静态 assets PNG 可加载 OK")
	return failed

func _check_pixel_art_export_api() -> int:
	var failed := 0
	# 导出用 API 仍可用（运行时不依赖）
	var sand := PixelArt.build_sand_tile(16)
	if sand == null or sand.get_width() != 16:
		printerr("build_sand_tile 失败")
		failed += 1
	var volcano := PixelArt.build_volcano_sprite(WorldConstants.SPRITE_VOLCANO)
	var baobab := PixelArt.build_baobab_sprite(WorldConstants.SPRITE_BAOBAB)
	var rose := PixelArt.build_rose_sprite(WorldConstants.SPRITE_ROSE)
	var prince := PixelArt.build_player_sprite(
		WorldConstants.SPRITE_PLAYER_W, WorldConstants.SPRITE_PLAYER_H
	)
	if volcano == null or baobab == null or rose == null or prince == null:
		printerr("PixelArt build_* 失败")
		failed += 1
	var art_src := FileAccess.get_file_as_string("res://scripts/pixel_art.gd")
	for forbidden in ["make_volcano_layers", "make_baobab_layers", "make_rose_layers"]:
		if art_src.find(forbidden) >= 0:
			printerr("PixelArt 仍含 %s" % forbidden)
			failed += 1
	# 运行时脚本不应再调用 PixelArt.make_*
	for runtime_path in [
		"res://scripts/player.gd",
		"res://scripts/surface_prop.gd",
		"res://scripts/planet_body.gd",
		"res://scripts/starfield.gd",
	]:
		var src := FileAccess.get_file_as_string(runtime_path)
		if src.find("PixelArt.make_") >= 0 or src.find("PixelArt.build_") >= 0:
			printerr("运行时脚本仍依赖 PixelArt 生成：%s" % runtime_path)
			failed += 1
	print("  PixelArt 导出 API / 运行时不依赖生成 OK")
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

	# 禁止旧 WorldHost / PlanetView / 鱼眼；允许新的像素 SubViewport
	if scene.get_node_or_null("WorldHost") != null:
		printerr("旧 WorldHost 结构仍存在")
		failed += 1
	if scene.get_node_or_null("PlanetView") != null:
		printerr("旧 PlanetView ColorRect 仍存在")
		failed += 1

	var game_view: SubViewportContainer = scene.get_node_or_null("GameView") as SubViewportContainer
	var game_viewport: SubViewport = scene.get_node_or_null(VIEWPORT_PATH) as SubViewport
	if game_view == null:
		printerr("找不到 SubViewportContainer GameView")
		failed += 1
	else:
		if not game_view.stretch:
			printerr("GameView.stretch 应为 true")
			failed += 1
		if game_view.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			printerr("GameView 应为 Nearest 过滤")
			failed += 1
	if game_viewport == null:
		printerr("找不到 SubViewport GameViewport")
		failed += 1
	else:
		if game_viewport.size != Vector2i(256, 224):
			printerr("GameViewport.size 应为 (256, 224)，实际 %s" % game_viewport.size)
			failed += 1

	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var player: Player = scene.get_node_or_null(PLAYER_PATH) as Player
	if planet == null:
		printerr("找不到 Planet（路径 %s）" % PLANET_PATH)
		failed += 1
	if player == null:
		printerr("找不到 Player（路径 %s）" % PLAYER_PATH)
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
		if planet.get_node_or_null("Surface") == null:
			printerr("找不到 Surface")
			failed += 1
		if planet.get_node_or_null("Body") == null:
			printerr("找不到 Body")
			failed += 1

	if planet != null and player != null:
		player.planet = planet
		# 改角后立刻同步：Body / Surface.rotation == -player_angle，玩家在弧顶
		player.set_angle_and_sync(0.75)
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

		# 精灵随半径相对基准缩放
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

		# 弧顶偏下：相对内部视口高度（256×224）
		var vp_h: float = float(WorldConstants.INTERNAL_HEIGHT)
		var apex_ratio: float = apex.y / vp_h
		if apex_ratio < 0.75:
			printerr("弧顶 Y 比例应偏下（≥0.75），实际 %s" % apex_ratio)
			failed += 1
		# 球心应在视口底边之外或极近底边，只露浅弧
		if planet.global_position.y < vp_h * 0.95:
			printerr(
				"球心应靠近/低于视口底边以浅露弧面，实际 y=%s / vh=%s"
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
