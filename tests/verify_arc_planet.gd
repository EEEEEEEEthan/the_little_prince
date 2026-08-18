extends SceneTree
## 头无模式验证：像素视口、静态 assets、圆弧力学、无旧伪 3D 残留。
## 用法：
##   ./.engine/.engine.exe --headless --path . --script res://tests/verify_arc_planet.gd

const VIEWPORT_PATH := "GameView/GameViewport"
const PLANET_PATH := "GameView/GameViewport/Planet"
const PLAYER_PATH := "GameView/GameViewport/Player"

const SKY_PHASE := preload("res://planet/sky_phase.gd")

const REQUIRED_ASSETS: Array[String] = [
	"res://player/prince.png",
	"res://planet/rose.png",
	"res://planet/volcano.png",
	"res://planet/baobab.png",
	"res://planet/body.png",
	"res://planet/starfield.png",
	"res://planet/day_sky.png",
]

func _init() -> void:
	call_deferred(&"_run_tests")

func _run_tests() -> void:
	var failed := 0
	failed += _check_constants()
	failed += _check_static_assets()
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
	if WorldConstants.BAOBAB_COUNT < 10:
		printerr("BAOBAB_COUNT 过少：%d" % WorldConstants.BAOBAB_COUNT)
		failed += 1
	if WorldConstants.PLANET_RADIUS < 40.0 or WorldConstants.PLANET_RADIUS > 60.0:
		printerr("PLANET_RADIUS 应在 40~60（内部 256×224）：%s" % WorldConstants.PLANET_RADIUS)
		failed += 1
	if WorldConstants.APEX_Y_RATIO < 0.80 or WorldConstants.APEX_Y_RATIO >= 1.0:
		printerr("APEX_Y_RATIO 应偏下（约 0.85~0.92）：%s" % WorldConstants.APEX_Y_RATIO)
		failed += 1
	if WorldConstants.VOLCANO_SPRITE_SIZE < 28 or WorldConstants.VOLCANO_SPRITE_SIZE > 48:
		printerr("VOLCANO_SPRITE_SIZE 应约 32~40，实际 %d" % WorldConstants.VOLCANO_SPRITE_SIZE)
		failed += 1
	if WorldConstants.BAOBAB_SPRITE_SIZE < 24 or WorldConstants.BAOBAB_SPRITE_SIZE > 40:
		printerr("BAOBAB_SPRITE_SIZE 应约 28~36，实际 %d" % WorldConstants.BAOBAB_SPRITE_SIZE)
		failed += 1
	if WorldConstants.ROSE_SPRITE_SIZE < 14 or WorldConstants.ROSE_SPRITE_SIZE > 26:
		printerr("ROSE_SPRITE_SIZE 应约 16~22，实际 %d" % WorldConstants.ROSE_SPRITE_SIZE)
		failed += 1
	if (
		WorldConstants.PLAYER_SPRITE_WIDTH < 10 or WorldConstants.PLAYER_SPRITE_WIDTH > 16
		or WorldConstants.PLAYER_SPRITE_HEIGHT < 14 or WorldConstants.PLAYER_SPRITE_HEIGHT > 24
	):
		printerr(
			"PLAYER_SPRITE 应约 12×18，实际 %dx%d"
			% [WorldConstants.PLAYER_SPRITE_WIDTH, WorldConstants.PLAYER_SPRITE_HEIGHT]
		)
		failed += 1
	# 旧伪 3D 常量不得残留在源码中
	var const_src := FileAccess.get_file_as_string("res://core/world_constants.gd")
	for legacy in [
		"TILE_SIZE", "MAP_TILES", "WORLD_PIXELS", "VIEWPORT_PIXELS",
		"LAYER_COUNT", "ROSE_LAYER_COUNT", "STACK_OUTWARD_EPSILON", "STACK_LEAN",
	]:
		if const_src.find(legacy) >= 0:
			printerr("world_constants.gd 仍含旧符号：%s" % legacy)
			failed += 1
	print("  常量检查 OK（半径 40~60 / 弧顶偏下 / 像素精灵）")
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
	# 星野应为以球心为中心的正方形
	var star: Texture2D = load("res://planet/starfield.png") as Texture2D
	if star != null:
		if star.get_width() != WorldConstants.STARFIELD_SIZE or star.get_height() != WorldConstants.STARFIELD_SIZE:
			printerr(
				"starfield 应为 %dx%d，实际 %dx%d"
				% [
					WorldConstants.STARFIELD_SIZE, WorldConstants.STARFIELD_SIZE,
					star.get_width(), star.get_height(),
				]
			)
			failed += 1
		var star_image := star.get_image()
		if star_image.get_pixel(0, 0).a > 0.01:
			printerr("starfield 背景应为纯透明")
			failed += 1
		var invalid_star_alpha := false
		for y in range(star_image.get_height()):
			for x in range(star_image.get_width()):
				var alpha := star_image.get_pixel(x, y).a
				if alpha > 0.01 and alpha < 0.99:
					printerr("starfield 像素 alpha 应为 0 或 1，位置 (%d,%d)，实际 %s" % [x, y, alpha])
					failed += 1
					invalid_star_alpha = true
					break
			if invalid_star_alpha:
				break
	# 白天天空应与星野同尺寸同中心，且为黑红渐变（红通道=高度坐标，供 shader 换色）
	var day_sky: Texture2D = load("res://planet/day_sky.png") as Texture2D
	if day_sky != null:
		if day_sky.get_width() != WorldConstants.STARFIELD_SIZE or day_sky.get_height() != WorldConstants.STARFIELD_SIZE:
			printerr(
				"day_sky 应为 %dx%d，实际 %dx%d"
				% [
					WorldConstants.STARFIELD_SIZE, WorldConstants.STARFIELD_SIZE,
					day_sky.get_width(), day_sky.get_height(),
				]
			)
			failed += 1
		var sky_image := day_sky.get_image()
		var top_color := sky_image.get_pixel(sky_image.get_width() / 2, 0)
		var bottom_color := sky_image.get_pixel(
			sky_image.get_width() / 2, sky_image.get_height() - 1
		)
		if top_color.r < 0.95 or top_color.g > 0.02 or top_color.b > 0.02:
			printerr("day_sky 顶部应为纯红（霞光坐标 1），实际 %s" % top_color.to_html(false))
			failed += 1
		if bottom_color.r > 0.05 or bottom_color.g > 0.02 or bottom_color.b > 0.02:
			printerr("day_sky 底部应为纯黑（天顶坐标 0），实际 %s" % bottom_color.to_html(false))
			failed += 1
	# 天空渐变资源：天顶/地平线两个 GradientTexture1D，X=相位（0 午夜、1/4 日出、
	# 1/2 正午、3/4 日落、1 午夜），关键相位须命中对应关键色
	var zenith_gradient: GradientTexture1D = load("res://planet/zenith_gradient.tres")
	var horizon_gradient: GradientTexture1D = load("res://planet/horizon_gradient.tres")
	if zenith_gradient == null:
		printerr("zenith_gradient.tres 应可加载为 GradientTexture1D")
		failed += 1
	if horizon_gradient == null:
		printerr("horizon_gradient.tres 应可加载为 GradientTexture1D")
		failed += 1
	if zenith_gradient != null and horizon_gradient != null:
		var zenith_cases := [
			[0.0, Color(0.01, 0.01, 0.04), "午夜天顶"],
			[0.25, Color(1.0, 0.7, 0.66), "日出天顶"],
			[0.5, Color(0.36, 0.6, 0.95), "正午天顶"],
			[0.75, Color(1.0, 0.3, 0.12), "日落天顶"],
			[1.0, Color(0.01, 0.01, 0.04), "午夜天顶"],
		]
		for item in zenith_cases:
			var got: Color = zenith_gradient.gradient.sample(item[0])
			if (
				absf(got.r - item[1].r) > 0.02
				or absf(got.g - item[1].g) > 0.02
				or absf(got.b - item[1].b) > 0.02
			):
				printerr(
					"zenith_gradient %s 应为 %s，实际 %s"
					% [item[2], item[1].to_html(false), got.to_html(false)]
				)
				failed += 1
		var horizon_cases := [
			[0.0, Color(0.02, 0.03, 0.08), "午夜地平线"],
			[0.25, Color(0.45, 0.55, 0.82), "日出地平线"],
			[0.5, Color(0.78, 0.88, 1.0), "正午地平线"],
			[0.75, Color(0.3, 0.22, 0.42), "日落地平线"],
			[1.0, Color(0.02, 0.03, 0.08), "午夜地平线"],
		]
		for item in horizon_cases:
			var got: Color = horizon_gradient.gradient.sample(item[0])
			if (
				absf(got.r - item[1].r) > 0.02
				or absf(got.g - item[1].g) > 0.02
				or absf(got.b - item[1].b) > 0.02
			):
				printerr(
					"horizon_gradient %s 应为 %s，实际 %s"
					% [item[2], item[1].to_html(false), got.to_html(false)]
				)
				failed += 1
	# 夜空透明度渐变（GradientTexture1D）应可加载；高度为 1，不走通用贴图尺寸检查
	var night_grad := load("res://planet/night_sky_gradient.tres")
	if night_grad == null or not (night_grad is GradientTexture1D):
		printerr("night_sky_gradient.tres 应可加载为 GradientTexture1D")
		failed += 1
	# 星球圆盘直径应约等于 2 * PLANET_RADIUS
	var body: Texture2D = load("res://planet/body.png") as Texture2D
	if body != null:
		var expected_diameter: int = int(ceil(WorldConstants.PLANET_RADIUS)) * 2
		if body.get_width() != expected_diameter or body.get_height() != expected_diameter:
			printerr(
				"body.png 应为 %dx%d，实际 %dx%d"
				% [expected_diameter, expected_diameter, body.get_width(), body.get_height()]
			)
			failed += 1
	# 精灵尺寸应对齐常量（火山 / 猴面包树为 spritesheet，宽度 = 帧数 × 帧尺寸）
	var sprite_checks: Array = [
		[
			"res://planet/volcano.png",
			WorldConstants.VOLCANO_SPRITE_SIZE * WorldConstants.VOLCANO_VARIANT_COUNT,
			WorldConstants.VOLCANO_SPRITE_SIZE,
		],
		[
			"res://planet/baobab.png",
			WorldConstants.BAOBAB_SPRITE_SIZE * WorldConstants.BAOBAB_VARIANT_COUNT,
			WorldConstants.BAOBAB_SPRITE_SIZE,
		],
		["res://planet/rose.png", WorldConstants.ROSE_SPRITE_SIZE, WorldConstants.ROSE_SPRITE_SIZE],
		["res://player/prince.png", WorldConstants.PLAYER_SPRITE_WIDTH, WorldConstants.PLAYER_SPRITE_HEIGHT],
	]
	for item in sprite_checks:
		var tex: Texture2D = load(item[0]) as Texture2D
		if tex == null:
			continue
		if tex.get_width() != int(item[1]) or tex.get_height() != int(item[2]):
			printerr(
				"%s 尺寸应为 %dx%d，实际 %dx%d"
				% [item[0], item[1], item[2], tex.get_width(), tex.get_height()]
			)
			failed += 1
	print("  静态 assets PNG 可加载 OK")
	return failed

func _check_no_legacy() -> int:
	var failed := 0
	for path in [
		"res://shaders/sphere_fisheye.gdshader",
		"res://scripts/stacked_prop.gd",
		"res://scripts/world_generator.gd",
		"res://scripts/planet_body.gd",
		"res://scripts/input_setup.gd",
	]:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			printerr("旧文件仍存在：%s" % path)
			failed += 1
	print("  无 sphere_fisheye / StackedProp 残留 OK")
	return failed

func _check_input_map() -> int:
	var failed := 0
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			printerr("InputMap 缺少动作或按键：%s" % action)
			failed += 1
	print("  InputMap move_* 动作 OK")
	return failed

func _check_scene_and_mechanics() -> int:
	var failed := 0
	var packed: PackedScene = load("res://main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

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
		var active_volcanoes := 0
		var dead_volcanoes := 0
		for prop in planet.surface_props:
			if prop.kind != SurfaceProp.Kind.VOLCANO:
				continue
			if prop.variant == WorldConstants.VOLCANO_ACTIVE_VARIANT:
				active_volcanoes += 1
			else:
				dead_volcanoes += 1
		if active_volcanoes != 1:
			printerr("活火山数量应为 1，实际 %d" % active_volcanoes)
			failed += 1
		if dead_volcanoes != WorldConstants.VOLCANO_DEAD_VARIANT_COUNT:
			printerr(
				"死火山数量应为 %d，实际 %d"
				% [WorldConstants.VOLCANO_DEAD_VARIANT_COUNT, dead_volcanoes]
			)
			failed += 1
		for prop in planet.surface_props:
			if (
				prop.kind == SurfaceProp.Kind.BAOBAB
				and (prop.variant < 0 or prop.variant >= WorldConstants.BAOBAB_VARIANT_COUNT)
			):
				printerr("猴面包树变体越界：%d" % prop.variant)
				failed += 1
		var expected_props: int = 1 + WorldConstants.VOLCANO_COUNT + WorldConstants.BAOBAB_COUNT
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
		if planet.get_node_or_null("Sky") == null:
			printerr("找不到 Sky（应为 Planet 子节点）")
			failed += 1
		if scene.get_node_or_null("GameView/GameViewport/Sky") != null:
			printerr("Sky 不应再作为 GameViewport 直接子节点")
			failed += 1

	if planet != null and player != null:
		planet.teleport_player(0.75)
		var surface: Node2D = planet.get_node("Surface") as Node2D
		var body: Node2D = planet.get_node("Body") as Node2D
		var sky = planet.get_node("Sky")
		if not is_equal_approx(surface.rotation, -planet.player_angle):
			printerr(
				"Surface.rotation 应为 %s，实际 %s"
				% [-planet.player_angle, surface.rotation]
			)
			failed += 1
		if not is_equal_approx(body.rotation, -planet.player_angle):
			printerr(
				"Body.rotation 应为 %s，实际 %s（本体须随星球转）"
				% [-planet.player_angle, body.rotation]
			)
			failed += 1
		if not is_equal_approx(body.rotation, surface.rotation):
			printerr("Body 与 Surface 旋转应一致")
			failed += 1
		if not is_equal_approx(sky.planet_rotation, -planet.player_angle):
			printerr(
				"Sky.planet_rotation 应为 %s，实际 %s（星空须随星球转）"
				% [-planet.player_angle, sky.planet_rotation]
			)
			failed += 1
		if WorldConstants.STAR_ROTATION_SPEED <= 0.0:
			printerr("STAR_ROTATION_SPEED 应大于 0（星空相对星球自转）")
			failed += 1
		# 统一天空 shader：检查 Sky 节点挂 ShaderMaterial，且关键参数均已绑定
		var sky_material := sky.material as ShaderMaterial
		if sky_material == null or sky_material.shader == null:
			printerr("Sky 应挂载统一天空 ShaderMaterial")
			failed += 1
		else:
			if sky.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
				printerr("Sky 应使用 LINEAR 过滤以平滑采样渐变贴图")
				failed += 1
			for param in ["zenith_gradient", "starfield_tex", "star_alpha_gradient", "noise_texture"]:
				var tex := sky_material.get_shader_parameter(param) as Texture2D
				if tex == null:
					printerr("Sky shader 应挂 %s" % param)
					failed += 1
			# 相位同步：_update_daylight 应将 phase 写入 shader
			for case in [
				[0.0, 0.5],
				[WorldConstants.DAY_HALF_ARC, 0.25],
				[PI, 0.0],
				[TAU - WorldConstants.DAY_HALF_ARC, 0.75],
			]:
				sky.rotation = case[0]
				sky._update_daylight()
				var phase: float = sky_material.get_shader_parameter("phase")
				if not is_equal_approx(phase, SKY_PHASE.angle_to_phase(case[0])):
					printerr(
						"相位(rotation=%s)应为 %s，实际 %s"
						% [case[0], SKY_PHASE.angle_to_phase(case[0]), phase]
					)
					failed += 1

		var apex := planet.apex_global_position()
		if player.global_position.distance_to(apex) > 0.5:
			printerr("玩家应在弧顶 %s，实际 %s" % [apex, player.global_position])
			failed += 1

		planet.teleport_player(fposmod(-0.2, TAU))
		if not is_equal_approx(surface.rotation, -planet.player_angle):
			printerr("负角时 Surface.rotation 不同步")
			failed += 1
		if not is_equal_approx(body.rotation, -planet.player_angle):
			printerr("负角时 Body.rotation 不同步")
			failed += 1
		if not is_equal_approx(sky.planet_rotation, -planet.player_angle):
			printerr("负角时 Sky.planet_rotation 不同步")
			failed += 1

		apex = planet.apex_global_position()
		var up := apex - planet.global_position
		if absf(up.x) > 0.5 or up.y >= 0.0:
			printerr("弧顶应在球心正上方，实际偏移 %s" % up)
			failed += 1
		if not is_equal_approx(up.length(), WorldConstants.PLANET_RADIUS):
			printerr(
				"弧顶距离应等于半径 %s，实际 %s"
				% [WorldConstants.PLANET_RADIUS, up.length()]
			)
			failed += 1

		# 弧顶偏下：相对内部视口高度
		var viewport_height := float(game_viewport.size.y)
		if apex.y / viewport_height < 0.75:
			printerr("弧顶 Y 比例应偏下（≥0.75），实际 %s" % (apex.y / viewport_height))
			failed += 1
		if planet.global_position.y < viewport_height * 0.95:
			printerr(
				"球心应靠近/低于视口底边以浅露弧面，实际 y=%s / vh=%s"
				% [planet.global_position.y, viewport_height]
			)
			failed += 1

	print("  场景与圆弧力学 OK")
	scene.queue_free()
	await process_frame
	return failed
