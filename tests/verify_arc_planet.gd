extends SceneTree
## 头无模式验证：像素视口、静态 assets、圆弧力学、无旧伪 3D 残留。
## 用法：
##   ./.engine/.engine.exe --headless --path . --script res://tests/verify_arc_planet.gd

const VIEWPORT_PATH := "GameView/GameViewport"
const PLANET_PATH := "GameView/GameViewport/Planet"
const PLAYER_PATH := "GameView/GameViewport/Player"
const PREVIOUS_PLANET_RADIUS := 72.8
const PREVIOUS_PLAYER_SPEED := 20.0
const PREVIOUS_STAR_ROTATION_SPEED := 0.02
const PREVIOUS_CLOUD_INSTANCE_COUNT := 84
const PREVIOUS_CLOUD_SPRITES_PER_MASS_MIN := 5
const PREVIOUS_CLOUD_SPRITES_PER_MASS_MAX := 8
const PREVIOUS_CLOUD_CLUSTER_RADIUS := Vector2(28.0, 10.0)
const PREVIOUS_CLOUD_INSTANCE_ALPHA_MAX := 0.52
const EXPECTED_PLANET_RADIUS := PREVIOUS_PLANET_RADIUS * 1.2
const EXPECTED_PLAYER_SPEED := PREVIOUS_PLAYER_SPEED * 0.8

const WorldConstants = preload("res://core/world_constants.gd")
const SKY_PHASE := preload("res://planet/sky_phase.gd")

const REQUIRED_ASSETS: Array[String] = [
	"res://player/prince.png",
	"res://planet/rose.png",
	"res://planet/volcano.png",
	"res://planet/pale_gray_puff.png",
	"res://planet/white_lavender_puff_frames.png",
	"res://planet/baobab.png",
	"res://planet/body.png",
	"res://planet/starfield.png",
	"res://planet/day_sky.png",
	"res://ui/prompt_a.png",
	"res://ui/portraits/prince.png",
	"res://ui/portraits/rose.png",
	"res://planet/glass_globe.png",
	"res://planet/migratory_bird.png",
]

const REQUIRED_OTHER_ASSETS: Array[String] = [
	"res://ui/typewriter.wav",
	"res://ui/fonts/fusion-pixel-8px-zh_hans.woff2",
]

func _init() -> void:
	call_deferred(&"_run_tests")

func _run_tests() -> void:
	var failed := 0
	failed += _check_constants()
	failed += _check_static_assets()
	failed += _check_no_legacy()
	failed += _check_tscn_editor_visible()
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
	if WorldConstants.BAOBAB_COUNT != 5:
		printerr("BAOBAB_COUNT 应为 5，实际 %d" % WorldConstants.BAOBAB_COUNT)
		failed += 1
	if absf(WorldConstants.PLANET_RADIUS - EXPECTED_PLANET_RADIUS) > 0.01:
		printerr(
			"PLANET_RADIUS 应为原值的 120%%（%s），实际 %s"
			% [EXPECTED_PLANET_RADIUS, WorldConstants.PLANET_RADIUS]
		)
		failed += 1
	if absf(WorldConstants.PLAYER_SPEED - EXPECTED_PLAYER_SPEED) > 0.01:
		printerr(
			"PLAYER_SPEED 应为原值的 80%%（%s），实际 %s"
			% [EXPECTED_PLAYER_SPEED, WorldConstants.PLAYER_SPEED]
		)
		failed += 1
	if WorldConstants.STAR_ROTATION_SPEED >= PREVIOUS_STAR_ROTATION_SPEED:
		printerr(
			"STAR_ROTATION_SPEED 应低于原值 %s：%s"
			% [PREVIOUS_STAR_ROTATION_SPEED, WorldConstants.STAR_ROTATION_SPEED]
		)
		failed += 1
	if (
		WorldConstants.CLOUD_DRIFT_SPEED <= 0.0
		or WorldConstants.CLOUD_DRIFT_SPEED >= WorldConstants.STAR_ROTATION_SPEED
	):
		printerr(
			"CLOUD_DRIFT_SPEED 应慢于星空自转 %s，实际 %s"
			% [WorldConstants.STAR_ROTATION_SPEED, WorldConstants.CLOUD_DRIFT_SPEED]
		)
		failed += 1
	if WorldConstants.CLOUD_INSTANCE_COUNT <= PREVIOUS_CLOUD_INSTANCE_COUNT:
		printerr(
				"CLOUD_INSTANCE_COUNT 应多于原值 %d，实际 %d"
				% [PREVIOUS_CLOUD_INSTANCE_COUNT, WorldConstants.CLOUD_INSTANCE_COUNT]
		)
		failed += 1
	if (
			WorldConstants.CLOUD_SPRITES_PER_MASS_MIN <= PREVIOUS_CLOUD_SPRITES_PER_MASS_MIN
			or WorldConstants.CLOUD_SPRITES_PER_MASS_MAX <= PREVIOUS_CLOUD_SPRITES_PER_MASS_MAX
	):
		printerr(
				"每团云朵数应多于原值 %d~%d，实际 %d~%d"
				% [
					PREVIOUS_CLOUD_SPRITES_PER_MASS_MIN,
					PREVIOUS_CLOUD_SPRITES_PER_MASS_MAX,
					WorldConstants.CLOUD_SPRITES_PER_MASS_MIN,
					WorldConstants.CLOUD_SPRITES_PER_MASS_MAX,
				]
		)
		failed += 1
	if (
			WorldConstants.CLOUD_CLUSTER_RADIUS.x <= PREVIOUS_CLOUD_CLUSTER_RADIUS.x
			or WorldConstants.CLOUD_CLUSTER_RADIUS.y <= PREVIOUS_CLOUD_CLUSTER_RADIUS.y
	):
		printerr(
				"CLOUD_CLUSTER_RADIUS 应大于原值 %s，实际 %s"
				% [PREVIOUS_CLOUD_CLUSTER_RADIUS, WorldConstants.CLOUD_CLUSTER_RADIUS]
		)
		failed += 1
	var previous_cluster_count_floor := (
			PREVIOUS_CLOUD_INSTANCE_COUNT / PREVIOUS_CLOUD_SPRITES_PER_MASS_MAX
	)
	var cluster_count_floor := (
			WorldConstants.CLOUD_INSTANCE_COUNT / WorldConstants.CLOUD_SPRITES_PER_MASS_MAX
	)
	if cluster_count_floor <= previous_cluster_count_floor:
		printerr(
				"云团数量应更多，下限由 %s 变为 %s"
				% [previous_cluster_count_floor, cluster_count_floor]
		)
		failed += 1
	if WorldConstants.CLOUD_INSTANCE_ALPHA_MAX > PREVIOUS_CLOUD_INSTANCE_ALPHA_MAX * 0.4:
		printerr(
				"CLOUD_INSTANCE_ALPHA_MAX 应远低于原值 %s，实际 %s"
				% [PREVIOUS_CLOUD_INSTANCE_ALPHA_MAX, WorldConstants.CLOUD_INSTANCE_ALPHA_MAX]
		)
		failed += 1
	if WorldConstants.CLOUD_ORBIT_MIN_RADIUS <= WorldConstants.PLANET_RADIUS:
		printerr(
			"CLOUD_ORBIT_MIN_RADIUS 应高于地表半径 %s，实际 %s"
			% [WorldConstants.PLANET_RADIUS, WorldConstants.CLOUD_ORBIT_MIN_RADIUS]
		)
		failed += 1
	if (
		WorldConstants.CLOUD_FRAME_WIDTH != 16
		or WorldConstants.CLOUD_FRAME_HEIGHT != 8
		or WorldConstants.CLOUD_FRAME_COLUMNS != 4
		or WorldConstants.CLOUD_FRAME_ROWS != 8
	):
		printerr(
				"云朵帧规格异常：%dx%d 网格 %dx%d"
				% [
					WorldConstants.CLOUD_FRAME_WIDTH,
					WorldConstants.CLOUD_FRAME_HEIGHT,
					WorldConstants.CLOUD_FRAME_COLUMNS,
					WorldConstants.CLOUD_FRAME_ROWS,
				]
		)
		failed += 1
	if WorldConstants.APEX_Y_RATIO < 0.80 or WorldConstants.APEX_Y_RATIO >= 1.0:
		printerr("APEX_Y_RATIO 应偏下（约 0.85~0.92）：%s" % WorldConstants.APEX_Y_RATIO)
		failed += 1
	if WorldConstants.VOLCANO_SPRITE_SIZE < 28 or WorldConstants.VOLCANO_SPRITE_SIZE > 48:
		printerr("VOLCANO_SPRITE_SIZE 应约 32~40，实际 %d" % WorldConstants.VOLCANO_SPRITE_SIZE)
		failed += 1
	if WorldConstants.INTERACT_RANGE_PX < 8.0 or WorldConstants.INTERACT_RANGE_PX > 28.0:
		printerr("INTERACT_RANGE_PX 应约 8~28，实际 %s" % WorldConstants.INTERACT_RANGE_PX)
		failed += 1
	if WorldConstants.INTERACT_PROMPT_LOCAL_Y > -24.0:
		printerr("INTERACT_PROMPT_LOCAL_Y 应在树冠上方（负值），实际 %s" % WorldConstants.INTERACT_PROMPT_LOCAL_Y)
		failed += 1
	if (
		WorldConstants.OVERHEAD_TYPEWRITER_LOCAL_Y > -16.0
		or WorldConstants.OVERHEAD_TYPEWRITER_LOCAL_Y < -40.0
	):
		printerr(
			"OVERHEAD_TYPEWRITER_LOCAL_Y 应在头顶附近，实际 %s"
			% WorldConstants.OVERHEAD_TYPEWRITER_LOCAL_Y
		)
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
	if (
		WorldConstants.PLAYER_IDLE_FRAME_COUNT < 1
		or WorldConstants.PLAYER_WALK_FRAME_COUNT < 2
		or WorldConstants.PLAYER_SPRITE_FRAME_COUNT
		!= WorldConstants.PLAYER_IDLE_FRAME_COUNT + WorldConstants.PLAYER_WALK_FRAME_COUNT
	):
		printerr(
			"小王子 spritesheet 应为 idle+walk，实际 idle=%d walk=%d total=%d"
			% [
				WorldConstants.PLAYER_IDLE_FRAME_COUNT,
				WorldConstants.PLAYER_WALK_FRAME_COUNT,
				WorldConstants.PLAYER_SPRITE_FRAME_COUNT,
			]
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
	print("  常量检查 OK（半径增加 20%% / 移速降低 20%% / 弧顶偏下 / 像素精灵）")
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
	for path in REQUIRED_OTHER_ASSETS:
		if not FileAccess.file_exists(path):
			printerr("缺少静态资源：%s" % path)
			failed += 1
			continue
		if load(path) == null:
			printerr("无法加载资源：%s" % path)
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
			[0.0, Color(0.1646875, 0.1178125, 0.136875), "午夜天顶"],
			[0.25, Color(0.48663607, 0.59763044, 0.84331489), "日出天顶"],
			[0.5, Color(0.45926034, 0.61566353, 0.90543872), "正午天顶"],
			[0.75, Color(0.35299647, 0.35156181, 0.45303002), "日落天顶"],
			[1.0, Color(0.16470589, 0.11764706, 0.13725491), "午夜天顶"],
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
		else:
			var body_img := body.get_image()
			var cx := float(body_img.get_width()) * 0.5
			var cy := float(body_img.get_height()) * 0.5
			var rmin := 1e9
			var rmax := 0.0
			for i in 64:
				var ang := TAU * float(i) / 64.0
				var dir := Vector2(sin(ang), -cos(ang))
				var last_r := 0.0
				for s in range(int(cx) + 2):
					var p := Vector2(cx, cy) + dir * float(s)
					var px := int(p.x)
					var py := int(p.y)
					if px < 0 or py < 0 or px >= body_img.get_width() or py >= body_img.get_height():
						break
					if body_img.get_pixel(px, py).a > 0.5:
						last_r = float(s)
				rmin = minf(rmin, last_r)
				rmax = maxf(rmax, last_r)
			if rmax - rmin < 1.0:
				printerr(
					"星球轮廓应有起伏，半径极差过小：%s..%s"
					% [rmin, rmax]
				)
				failed += 1
			# 禁止 Bayer 棋盘渐变：高对比相邻像素不应占主导
			var checker := 0
			var opaque_pairs := 0
			for y in range(1, body_img.get_height()):
				for x in range(1, body_img.get_width()):
					var a := body_img.get_pixel(x, y)
					var bcol := body_img.get_pixel(x - 1, y)
					if a.a < 0.5 or bcol.a < 0.5:
						continue
					opaque_pairs += 1
					var d := a.r - bcol.r
					if absf(d) > 0.12:
						checker += 1
			if opaque_pairs > 0 and float(checker) / float(opaque_pairs) > 0.18:
				printerr("星球贴图不应使用 1bit/Bayer 渐变")
				failed += 1
	# 精灵尺寸应对齐常量（火山 / 猴面包树为 spritesheet，宽度 = 帧数 × 帧尺寸）
	var sprite_checks: Array = [
		[
			"res://planet/volcano.png",
			WorldConstants.VOLCANO_SPRITE_SIZE * WorldConstants.VOLCANO_VARIANT_COUNT,
			WorldConstants.VOLCANO_SPRITE_SIZE,
		],
		["res://planet/pale_gray_puff.png", 8, 8],
		[
			"res://planet/white_lavender_puff_frames.png",
			WorldConstants.CLOUD_FRAME_WIDTH * WorldConstants.CLOUD_FRAME_COLUMNS,
			WorldConstants.CLOUD_FRAME_HEIGHT * WorldConstants.CLOUD_FRAME_ROWS,
		],
		[
			"res://planet/baobab.png",
			WorldConstants.BAOBAB_SPRITE_SIZE * WorldConstants.BAOBAB_VARIANT_COUNT,
			WorldConstants.BAOBAB_SPRITE_SIZE,
		],
		["res://planet/rose.png", WorldConstants.ROSE_SPRITE_SIZE, WorldConstants.ROSE_SPRITE_SIZE],
		[
			"res://player/prince.png",
			WorldConstants.PLAYER_SPRITE_WIDTH * WorldConstants.PLAYER_SPRITE_FRAME_COUNT,
			WorldConstants.PLAYER_SPRITE_HEIGHT,
		],
		["res://ui/prompt_a.png", 13, 13],
		["res://ui/portraits/prince.png", 32, 32],
		["res://ui/portraits/rose.png", 32, 32],
		["res://planet/glass_globe.png", 24, 24],
		["res://planet/migratory_bird.png", 16, 8],
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
	var volcano_tex := load("res://planet/volcano.png") as Texture2D
	if volcano_tex != null:
		var volcano_img := volcano_tex.get_image()
		var frame_size := WorldConstants.VOLCANO_SPRITE_SIZE
		var active_origin := WorldConstants.VOLCANO_ACTIVE_VARIANT * frame_size
		var found_lava := false
		var found_smoke_pixel := false
		for pixel_y in range(frame_size):
			for pixel_x in range(active_origin, active_origin + frame_size):
				var pixel := volcano_img.get_pixel(pixel_x, pixel_y)
				if pixel.a < 0.5:
					continue
				if pixel.s > 0.45 and pixel.r > pixel.b + 0.2:
					found_lava = true
				if pixel.s < 0.18 and pixel.v > 0.45:
					found_smoke_pixel = true
		if not found_lava:
			printerr("活火山帧应含熔岩色")
			failed += 1
		if found_smoke_pixel:
			printerr("活火山贴图不应再含烟雾像素")
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

func _check_tscn_editor_visible() -> int:
	var failed := 0
	for path in [
		"res://main.tscn",
		"res://planet/planet.tscn",
		"res://planet/b612.tscn",
		"res://ui/dialogue_box.tscn",
		"res://ui/overhead_typewriter.tscn",
	]:
		var src := FileAccess.get_file_as_string(path)
		if src.contains("visible = false"):
			printerr("%s 不应在 tscn 写 visible = false（编辑器要能看见，运行时脚本再关）" % path)
			failed += 1
	print("  tscn 编辑器可见 OK")
	return failed

func _check_input_map() -> int:
	var failed := 0
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"interact"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			printerr("InputMap 缺少动作或按键：%s" % action)
			failed += 1
	if InputMap.has_action(&"interact"):
		var has_enter := false
		var has_joy_a := false
		for event in InputMap.action_get_events(&"interact"):
			var key := event as InputEventKey
			if key != null and key.physical_keycode == KEY_ENTER:
				has_enter = true
			var joy := event as InputEventJoypadButton
			if joy != null and joy.button_index == JOY_BUTTON_A:
				has_joy_a = true
		if not has_enter:
			printerr("interact 应绑定键盘 Enter（Submit）")
			failed += 1
		if not has_joy_a:
			printerr("interact 应绑定手柄 A（JOY_BUTTON_A）")
			failed += 1
	print("  InputMap move_* / interact 动作 OK")
	return failed

func _check_scene_and_mechanics() -> int:
	var failed := 0
	var packed: PackedScene = load("res://main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/B612Story") as B612Story).auto_start = false
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
				for child in prop.get_children():
					if child is CPUParticles2D:
						printerr("死火山 %s 不应有粒子" % prop.name)
						failed += 1
		if active_volcanoes != 1:
			printerr("活火山数量应为 1，实际 %d" % active_volcanoes)
			failed += 1
		if dead_volcanoes != WorldConstants.VOLCANO_DEAD_VARIANT_COUNT:
			printerr(
				"死火山数量应为 %d，实际 %d"
				% [WorldConstants.VOLCANO_DEAD_VARIANT_COUNT, dead_volcanoes]
			)
			failed += 1
		var volcano_smoke := planet.get_node_or_null("%VolcanoSmoke") as CPUParticles2D
		if volcano_smoke == null:
			printerr("活火山应有 VolcanoSmoke 粒子")
			failed += 1
		else:
			if not volcano_smoke.emitting:
				printerr("VolcanoSmoke 应为 emitting")
				failed += 1
			if not volcano_smoke.local_coords:
				printerr("VolcanoSmoke 应使用 local_coords（随火山旋转）")
				failed += 1
			if volcano_smoke.texture == null:
				printerr("VolcanoSmoke 应有 puff 贴图")
				failed += 1
			const PREVIOUS_SMOKE_VELOCITY_MAX := 11.0
			const PREVIOUS_SMOKE_GRAVITY_Y := -14.0
			const PREVIOUS_SMOKE_LIFETIME := 2.2
			if volcano_smoke.initial_velocity_max >= PREVIOUS_SMOKE_VELOCITY_MAX * 0.5:
				printerr("VolcanoSmoke 初速应大幅低于原值")
				failed += 1
			if volcano_smoke.gravity.y <= PREVIOUS_SMOKE_GRAVITY_Y * 0.5:
				printerr("VolcanoSmoke 上升加速度应大幅低于原值")
				failed += 1
			if volcano_smoke.lifetime <= PREVIOUS_SMOKE_LIFETIME * 1.5:
				printerr("VolcanoSmoke 寿命应加长以匹配慢速")
				failed += 1
			var smoke_host := volcano_smoke.get_parent() as SurfaceProp
			if (
				smoke_host == null
				or smoke_host.kind != SurfaceProp.Kind.VOLCANO
				or smoke_host.variant != WorldConstants.VOLCANO_ACTIVE_VARIANT
			):
				printerr("VolcanoSmoke 应挂在活火山上")
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
		if planet.get_node_or_null("Clouds") == null:
			printerr("找不到 Clouds（应为 Planet 子节点）")
			failed += 1
		if not planet.body.scale.is_equal_approx(Vector2.ONE):
			printerr("Body.scale 应为 (1,1)（贴图原尺寸显示），实际 %s" % planet.body.scale)
			failed += 1
		for prop in planet.surface_props:
			var dist := prop.position.length()
			# 允许沿起伏轮廓略微内缩，但不得停在放大前的旧圆上。
			if dist < PREVIOUS_PLANET_RADIUS or dist > planet.radius + 1.5:
				printerr(
					"地物 %s 应靠近半径 %s，实际 %s"
					% [prop.name, planet.radius, dist]
				)
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
		failed += _check_clouds(planet)
		if not is_equal_approx(planet.player_angle, 0.75):
			printerr("云层检查后 player_angle 应恢复为 0.75")
			failed += 1
		if planet.star_rotation_speed <= 0.0:
			printerr("star_rotation_speed 应大于 0（星空相对星球自转）")
			failed += 1
		if not is_equal_approx(sky.star_rotation_speed, planet.star_rotation_speed):
			printerr("Sky.star_rotation_speed 应与 Planet 导出一致")
			failed += 1
		if not is_equal_approx(planet.radius, WorldConstants.PLANET_RADIUS):
			printerr(
				"B612 半径应等于默认常量 %s，实际 %s"
				% [WorldConstants.PLANET_RADIUS, planet.radius]
			)
			failed += 1
		failed += await _check_planet_base_scene()
		# 统一天空 shader：检查 Sky 节点挂 ShaderMaterial，且关键参数均已绑定
		var sky_material := sky.material as ShaderMaterial
		if sky_material == null or sky_material.shader == null:
			printerr("Sky 应挂载统一天空 ShaderMaterial")
			failed += 1
		else:
			if sky.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
				printerr("Sky 应使用 NEAREST 过滤")
				failed += 1
			if sky.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
				printerr("Sky 应使用 NEAREST 过滤")
				failed += 1
			if sky.texture == null or sky.texture.resource_path != "res://planet/starfield.png":
				printerr("Sky.texture 应为 starfield.png")
				failed += 1
			for line in sky_material.shader.code.split("\n"):
				if line.begins_with("uniform sampler2D") and not line.contains("filter_nearest"):
					printerr("Sky shader sampler 应使用 filter_nearest：%s" % line)
					failed += 1
			for param in ["zenith_gradient", "star_alpha_gradient", "noise_texture"]:
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
		var expected_apex_y := float(game_viewport.size.y) * WorldConstants.APEX_Y_RATIO
		if absf(apex.y - expected_apex_y) > 0.5:
			printerr(
				"增大半径后弧顶 Y 仍应保持不变，期望 %s，实际 %s"
				% [expected_apex_y, apex.y]
			)
			failed += 1
		if player.global_position.distance_to(apex) > 0.5:
			printerr("玩家应在弧顶 %s，实际 %s" % [apex, player.global_position])
			failed += 1
		if player.hframes != WorldConstants.PLAYER_SPRITE_FRAME_COUNT:
			printerr(
				"Player.hframes 应为 %d，实际 %d"
				% [WorldConstants.PLAYER_SPRITE_FRAME_COUNT, player.hframes]
			)
			failed += 1
		if not player.scale.is_equal_approx(Vector2.ONE):
			printerr("Player.scale 应为 (1,1)，实际 %s" % player.scale)
			failed += 1
		var expected_offset_y := (
			-float(WorldConstants.PLAYER_SPRITE_HEIGHT) * 0.5 + WorldConstants.PLAYER_VISUAL_Y_OFFSET
		)
		if absf(player.offset.y - expected_offset_y) > 0.01:
			printerr("玩家视觉 Y 偏移应为 %s，实际 %s" % [expected_offset_y, player.offset.y])
			failed += 1
		player._update_animation(0.0, 0.6)
		if player.frame < 0 or player.frame >= WorldConstants.PLAYER_IDLE_FRAME_COUNT:
			printerr("静止时应停在 idle 帧，实际 frame=%d" % player.frame)
			failed += 1
		planet.move_player(1.0, 0.2)
		player._update_animation(1.0, 0.2)
		if not planet.is_moving():
			printerr("输入右移后星球应仍有角速度")
			failed += 1
		if player.frame < WorldConstants.PLAYER_IDLE_FRAME_COUNT:
			printerr("行走时应切到 walk 帧，实际 frame=%d" % player.frame)
			failed += 1
		if player.flip_h:
			printerr("向右走时 flip_h 应为 false")
			failed += 1
		planet.move_player(-1.0, 0.2)
		player._update_animation(-1.0, 0.05)
		if not player.flip_h:
			printerr("向左走时 flip_h 应为 true")
			failed += 1

		failed += _check_scarf(player, planet)

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
		var clouds_after_negative = planet.get_node("Clouds")
		if not is_equal_approx(clouds_after_negative.planet_rotation, -planet.player_angle):
			printerr("负角时 Clouds.planet_rotation 不同步")
			failed += 1

		apex = planet.apex_global_position()
		var up := apex - planet.global_position
		if absf(up.x) > 0.5 or up.y >= 0.0:
			printerr("弧顶应在球心正上方，实际偏移 %s" % up)
			failed += 1
		if not is_equal_approx(up.length(), planet.radius):
			printerr(
				"弧顶距离应等于半径 %s，实际 %s"
				% [planet.radius, up.length()]
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

		failed += await _check_overhead_typewriter(scene, planet)
		failed += await _check_prop_interactions(scene, planet)
		failed += await _check_b612_story(scene, planet)

	print("  场景与圆弧力学 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_clouds(planet: Planet) -> int:
	var failed := 0
	var original_player_angle := planet.player_angle
	var clouds = planet.get_node("Clouds")
	var cloud_sprites := planet.get_node("%CloudSprites") as MultiMeshInstance2D
	var cloud_multimesh := cloud_sprites.multimesh
	if cloud_sprites.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		printerr("CloudSprites 应使用 NEAREST 过滤")
		failed += 1
	if cloud_sprites.texture.resource_path != "res://planet/white_lavender_puff_frames.png":
		printerr("CloudSprites.texture 应为 white_lavender_puff_frames.png")
		failed += 1
	var cloud_material := cloud_sprites.material as ShaderMaterial
	if cloud_material == null or cloud_material.shader == null:
		printerr("CloudSprites 应挂载帧动画 ShaderMaterial")
		failed += 1
	elif cloud_material.shader.resource_path != "res://planet/cloud_frame.gdshader":
		printerr("CloudSprites shader 应为 cloud_frame.gdshader")
		failed += 1
	if cloud_multimesh.instance_count != WorldConstants.CLOUD_INSTANCE_COUNT:
		printerr(
				"云朵实例数应为 %d，实际 %d"
				% [WorldConstants.CLOUD_INSTANCE_COUNT, cloud_multimesh.instance_count]
		)
		failed += 1
	if clouds._instance_local_positions.size() != WorldConstants.CLOUD_INSTANCE_COUNT:
		printerr(
				"云朵布局数应为 %d，实际 %d"
				% [WorldConstants.CLOUD_INSTANCE_COUNT, clouds._instance_local_positions.size()]
		)
		failed += 1
	var cloud_image := cloud_sprites.texture.get_image()
	var punched_hole_count := 0
	for pixel_y in range(1, cloud_image.get_height() - 1):
		for pixel_x in range(1, cloud_image.get_width() - 1):
			if cloud_image.get_pixel(pixel_x, pixel_y).a > 0.05:
				continue
			var opaque_neighbor_count := 0
			for neighbor in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				if cloud_image.get_pixel(pixel_x + neighbor.x, pixel_y + neighbor.y).a > 0.5:
					opaque_neighbor_count += 1
			if opaque_neighbor_count >= 4:
				punched_hole_count += 1
	if punched_hole_count > 0:
		printerr("云朵贴图不应掏洞，内部镂空 %d 像素" % punched_hole_count)
		failed += 1
	var opaque_weighted_y := 0.0
	var opaque_pixel_count := 0
	for pixel_y in cloud_image.get_height():
		for pixel_x in cloud_image.get_width():
			if cloud_image.get_pixel(pixel_x, pixel_y).a <= 0.05:
				continue
			var frame_local_y := pixel_y % WorldConstants.CLOUD_FRAME_HEIGHT
			opaque_weighted_y += float(frame_local_y)
			opaque_pixel_count += 1
	if opaque_pixel_count == 0:
		printerr("云朵贴图没有不透明像素")
		failed += 1
	else:
		var opaque_centroid_y := opaque_weighted_y / float(opaque_pixel_count)
		if opaque_centroid_y >= float(WorldConstants.CLOUD_FRAME_HEIGHT) * 0.5:
			printerr(
					"云朵应蓬松顶朝上，质心 y=%s"
					% opaque_centroid_y
			)
			failed += 1
	if not is_equal_approx(clouds.planet_rotation, -planet.player_angle):
		printerr(
				"Clouds.planet_rotation 应为 %s，实际 %s"
				% [-planet.player_angle, clouds.planet_rotation]
		)
		failed += 1
	var distances: PackedFloat32Array = PackedFloat32Array()
	distances.resize(clouds._instance_local_positions.size())
	var used_rows := {}
	var lowest_orbit := INF
	var highest_orbit := 0.0
	var renderer_keeps_instance_data := cloud_multimesh.buffer.size() > 0
	for instance_index in clouds._instance_local_positions.size():
		var local_position: Vector2 = clouds._instance_local_positions[instance_index]
		var orbit_distance := local_position.length()
		distances[instance_index] = orbit_distance
		lowest_orbit = minf(lowest_orbit, orbit_distance)
		highest_orbit = maxf(highest_orbit, orbit_distance)
		if orbit_distance < planet.cloud_orbit_min_radius - 1.0:
			printerr(
					"实例 %d 轨道应更高，距离 %s，下限 %s"
					% [instance_index, orbit_distance, planet.cloud_orbit_min_radius]
			)
			failed += 1
		var instance_color: Color = clouds._instance_colors[instance_index]
		if (
				instance_color.a < WorldConstants.CLOUD_INSTANCE_ALPHA_MIN - 0.001
				or instance_color.a > WorldConstants.CLOUD_INSTANCE_ALPHA_MAX + 0.001
		):
			printerr("实例 %d 应更透明，alpha=%s" % [instance_index, instance_color.a])
			failed += 1
		used_rows[int(round(instance_color.r * float(WorldConstants.CLOUD_FRAME_ROWS - 1)))] = true
		var expected_rotation := atan2(local_position.x, -local_position.y)
		if renderer_keeps_instance_data:
			var instance_transform := cloud_multimesh.get_instance_transform_2d(instance_index)
			if instance_transform.get_scale().x > 0.0:
				if absf(angle_difference(instance_transform.get_rotation(), expected_rotation)) > 0.02:
					printerr(
							"实例 %d 应看向行星，rotation=%s 位置=%s"
							% [instance_index, instance_transform.get_rotation(), local_position]
					)
					failed += 1
	if highest_orbit - lowest_orbit < 8.0:
		printerr("云团轨道高度应有差异，极差 %s" % (highest_orbit - lowest_orbit))
		failed += 1
	if used_rows.size() < 4:
		printerr("云朵变体过少：%d" % used_rows.size())
		failed += 1
	var sample_local_position: Vector2 = clouds._instance_local_positions[0]
	var rotation_before: float = clouds.rotation
	var angle_before: float = (
			clouds.to_global(sample_local_position) - clouds.global_position
	).angle()
	planet.teleport_player(fposmod(planet.player_angle + 0.4, TAU))
	if not is_equal_approx(clouds.planet_rotation, -planet.player_angle):
		printerr("传送后 Clouds 应跟随星球旋转")
		failed += 1
	var angle_after: float = (
			clouds.to_global(sample_local_position) - clouds.global_position
	).angle()
	if absf(angle_difference(angle_after, angle_before - 0.4)) > 0.02:
		printerr(
				"云朵应随星球旋转，期望角变 %s，实际 %s -> %s"
				% [-0.4, angle_before, angle_after]
		)
		failed += 1
	for instance_index in clouds._instance_local_positions.size():
		var orbit_distance: float = clouds._instance_local_positions[instance_index].length()
		if absf(orbit_distance - distances[instance_index]) > 0.51:
			printerr(
					"实例 %d 轨道半径不应变，期望 %s 实际 %s"
					% [instance_index, distances[instance_index], orbit_distance]
			)
			failed += 1
	var drift_seconds := 8.0
	clouds._process(drift_seconds)
	var expected_drift := planet.cloud_drift_speed * drift_seconds
	if absf(angle_difference(clouds.rotation, rotation_before + expected_drift - 0.4)) > 0.02:
		printerr(
				"云层应顺时针缓慢飘动，期望转过 %s，实际 %s -> %s"
				% [expected_drift, rotation_before, clouds.rotation]
		)
		failed += 1
	if not is_equal_approx(clouds.drift_speed, planet.cloud_drift_speed):
		printerr("Clouds.drift_speed 应与 Planet 导出一致")
		failed += 1
	if cloud_sprites.texture.resource_path != planet.cloud_texture.resource_path:
		printerr("CloudSprites.texture 应与 Planet.cloud_texture 一致")
		failed += 1
	for instance_index in clouds._instance_local_positions.size():
		var orbit_distance: float = clouds._instance_local_positions[instance_index].length()
		if absf(orbit_distance - distances[instance_index]) > 0.51:
			printerr("实例 %d 飘动后轨道半径不应变" % instance_index)
			failed += 1
	planet.teleport_player(original_player_angle)
	print("  云层轨道 / 朝向 / 慢飘 OK")
	return failed


func _check_planet_base_scene() -> int:
	var failed := 0
	var packed: PackedScene = load("res://planet/planet.tscn")
	if packed == null:
		printerr("无法加载可复用基底 planet.tscn")
		return 1
	var base := packed.instantiate() as Planet
	if base == null:
		printerr("planet.tscn 根节点应为 Planet")
		return 1
	root.add_child(base)
	await process_frame
	if base.get_node("Surface").get_child_count() != 0:
		printerr("可复用基底 Surface 应为空，地物放在具体星球场景")
		failed += 1
	if base.get_node_or_null("%Body") == null:
		printerr("基底应有 Body")
		failed += 1
	if base.get_node_or_null("%Sky") == null:
		printerr("基底应有 Sky")
		failed += 1
	if base.get_node_or_null("%Clouds") == null:
		printerr("基底应有 Clouds")
		failed += 1
	if base.body_texture == null or base.starfield_texture == null:
		printerr("基底应导出默认贴图")
		failed += 1
	base.queue_free()
	await process_frame
	print("  可复用 planet 基底 OK")
	return failed


func _check_scarf(player: Player, planet: Planet) -> int:
	var failed := 0
	var scarf := player.get_node("Scarf") as Scarf
	if scarf == null:
		printerr("Player 下应有 Scarf 节点")
		return 1
	if scarf.simulated_positions.size() != Scarf.POINT_COUNT:
		printerr(
				"围巾质点数应为 %d，实际 %d"
				% [Scarf.POINT_COUNT, scarf.simulated_positions.size()]
		)
		failed += 1
	if Scarf.DISPLAY_FPS > WorldConstants.PLAYER_WALK_FPS:
		printerr(
				"围巾抽帧帧率应不超过走路帧率 %s，实际 %s"
				% [WorldConstants.PLAYER_WALK_FPS, Scarf.DISPLAY_FPS]
		)
		failed += 1
	planet.teleport_player(planet.player_angle)
	player.flip_h = false
	player.frame = 0
	var settle_delta := 1.0 / 60.0
	for _step_index in 48:
		scarf._physics_process(settle_delta)
	failed += _assert_scarf_integer_display(scarf)
	var neck := scarf.simulated_positions[0]
	var tip := scarf.simulated_positions[Scarf.POINT_COUNT - 1]
	if tip.y <= neck.y + 1.0:
		printerr("静止围巾应下垂，neck=%s tip=%s" % [neck, tip])
		failed += 1
	if tip.x >= neck.x:
		printerr("面朝右静止时围巾应偏左，neck=%s tip=%s" % [neck, tip])
		failed += 1
	var step_delta := 1.0 / 30.0
	for _step_index in 48:
		planet.move_player(1.0, step_delta)
		player._update_animation(1.0, step_delta)
		scarf._physics_process(step_delta)
	neck = scarf.simulated_positions[0]
	tip = scarf.simulated_positions[Scarf.POINT_COUNT - 1]
	if tip.x >= neck.x - 1.0:
		printerr("向右走时围巾应拖在左侧，neck=%s tip=%s" % [neck, tip])
		failed += 1
	failed += _assert_scarf_integer_display(scarf)
	for _step_index in 48:
		planet.move_player(-1.0, step_delta)
		player._update_animation(-1.0, step_delta)
		scarf._physics_process(step_delta)
	neck = scarf.simulated_positions[0]
	tip = scarf.simulated_positions[Scarf.POINT_COUNT - 1]
	if tip.x <= neck.x + 1.0:
		printerr("向左走时围巾应拖在右侧，neck=%s tip=%s" % [neck, tip])
		failed += 1
	failed += _assert_scarf_integer_display(scarf)
	print("  围巾 Verlet / 抽帧 OK")
	return failed


func _assert_scarf_integer_display(scarf: Scarf) -> int:
	for point in scarf.display_positions:
		if not point.is_equal_approx(point.round()):
			printerr("围巾抽帧坐标应为整数，实际 %s" % point)
			return 1
	return 0


func _check_overhead_typewriter(scene: Node, planet: Planet) -> int:
	var failed := 0
	var overhead := scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	var body := overhead.get_node("Body") as Label
	if body.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		printerr("头顶文字应水平居中")
		failed += 1
	var font_color: Color = body.get("theme_override_colors/font_color")
	if font_color != Color.WHITE:
		printerr("头顶文字应为纯白，实际 %s" % font_color)
		failed += 1
	var expected_position := (
			planet.apex_global_position() + Vector2(0.0, WorldConstants.OVERHEAD_TYPEWRITER_LOCAL_Y)
	).round()
	if overhead.global_position.distance_to(expected_position) > 0.5:
		printerr(
			"头顶打字机应在弧顶上方 %s，实际 %s"
			% [expected_position, overhead.global_position]
		)
		failed += 1

	var line := OverheadTypewriter.AMBIENT_LINES[0]
	overhead.play(line)
	if not overhead.visible:
		printerr("play 后头顶打字机应可见")
		failed += 1
	if body.text != line:
		printerr("play 后应显示氛围文字")
		failed += 1
	if body.visible_characters != 1:
		printerr(
			"play 后应立刻打出第一个字，实际 visible_characters=%d"
			% body.visible_characters
		)
		failed += 1
	await create_timer(OverheadTypewriter.TYPEWRITER_INTERVAL * 3.0).timeout
	if body.visible_characters <= 1:
		printerr("打字机应继续出字，实际 visible_characters=%d" % body.visible_characters)
		failed += 1
	var typed_deadline_msec := Time.get_ticks_msec() + 2000
	while (
			body.visible_characters < line.length()
			and Time.get_ticks_msec() < typed_deadline_msec
	):
		await process_frame
	if body.visible_characters < line.length():
		printerr("打字机超时未打完")
		failed += 1
	if not overhead.visible:
		printerr("打完后应停留显示")
		failed += 1
	var fade_deadline_msec := Time.get_ticks_msec() + int(
			(
				OverheadTypewriter.HOLD_DURATION_SECONDS
				+ OverheadTypewriter.FADE_DURATION_SECONDS
				+ 0.5
			) * 1000.0
	)
	while overhead.visible and Time.get_ticks_msec() < fade_deadline_msec:
		await process_frame
	if overhead.visible:
		printerr("停留后应渐隐并隐藏")
		failed += 1
	failed += await _check_overhead_queue(overhead)
	print("  头顶打字机 OK")
	return failed


func _check_overhead_queue(overhead: OverheadTypewriter) -> int:
	var failed := 0
	var body := overhead.get_node("Body") as Label
	var first_line := "甲"
	var second_line := "乙"
	overhead.play_queued(first_line)
	await process_frame
	if body.text != first_line:
		printerr("队列第一句应立即开始")
		failed += 1
	var first_started_msec := Time.get_ticks_msec()
	overhead.play_queued(second_line)
	await process_frame
	if body.text != first_line:
		printerr("正在播的头顶叙事结束前不应插播下一句")
		failed += 1
	var second_started_msec := -1
	var second_deadline_msec := first_started_msec + 8000
	while Time.get_ticks_msec() < second_deadline_msec:
		if overhead.visible and body.text == second_line:
			second_started_msec = Time.get_ticks_msec()
			break
		await process_frame
	if second_started_msec < 0:
		printerr("队列第二句未出现")
		return failed + 1
	var expected_interval_msec := int(
			(
				OverheadTypewriter.HOLD_DURATION_SECONDS
				+ OverheadTypewriter.FADE_DURATION_SECONDS
				+ OverheadTypewriter.QUEUE_GAP_SECONDS
			)
			* 1000.0
	)
	var actual_interval_msec := second_started_msec - first_started_msec
	if absi(actual_interval_msec - expected_interval_msec) > 500:
		printerr(
				"头顶叙事队列间隔应为约 %d ms，实际 %d ms"
				% [expected_interval_msec, actual_interval_msec]
		)
		failed += 1
	var idle_deadline_msec := Time.get_ticks_msec() + 5000
	while overhead.visible and Time.get_ticks_msec() < idle_deadline_msec:
		await process_frame
	return failed


func _check_prop_interactions(scene: Node, planet: Planet) -> int:
	var failed := 0
	if scene.get_node_or_null("GameView/GameViewport/Interaction") == null:
		printerr("找不到 Interaction")
		failed += 1
	if scene.get_node_or_null("GameView/GameViewport/InteractPrompt") == null:
		printerr("找不到 InteractPrompt")
		failed += 1
	var dialogue: DialogueBox = scene.get_node_or_null("GameView/GameViewport/DialogueBox") as DialogueBox
	if dialogue == null:
		printerr("找不到 DialogueBox")
		failed += 1

	var baobab: SurfaceProp = null
	var rose: SurfaceProp = null
	var active_volcano: SurfaceProp = null
	var dead_volcano: SurfaceProp = null
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.BAOBAB:
				if baobab == null:
					baobab = prop
			SurfaceProp.Kind.ROSE:
				rose = prop
			SurfaceProp.Kind.VOLCANO:
				if prop.variant == WorldConstants.VOLCANO_ACTIVE_VARIANT:
					active_volcano = prop
				elif dead_volcano == null:
					dead_volcano = prop
	if baobab == null:
		printerr("场景中没有猴面包树")
		return failed + 1
	if rose.get_node_or_null("GlassGlobe") == null:
		printerr("玫瑰下应有 GlassGlobe")
		failed += 1
	var shoot_count := 0
	for prop in planet.surface_props:
		if prop.kind == SurfaceProp.Kind.BAOBAB:
			shoot_count += 1
	if shoot_count != WorldConstants.BAOBAB_COUNT:
		printerr(
				"猴面包嫩芽数量应为 %d，实际 %d"
				% [WorldConstants.BAOBAB_COUNT, shoot_count]
		)
		failed += 1
	if active_volcano == null:
		printerr("场景中没有活火山")
		return failed + 1
	if dead_volcano == null:
		printerr("场景中没有死火山")
		return failed + 1

	failed += _assert_focus(planet, baobab, &"baobab_shoot", "猴面包树")
	failed += _assert_focus(planet, rose, &"rose", "玫瑰")
	if active_volcano.is_interactable() or dead_volcano.is_interactable():
		printerr("火山只作为装饰，不应可交互")
		failed += 1
	planet.teleport_player(active_volcano.rotation)
	if planet.find_nearest_interactable() == active_volcano:
		printerr("站在火山旁不应选中火山")
		failed += 1

	planet.teleport_player(baobab.rotation)
	await process_frame
	var prompt: InteractPrompt = scene.get_node_or_null("GameView/GameViewport/InteractPrompt") as InteractPrompt
	if prompt != null:
		if prompt.get_parent() == baobab:
			printerr("A 提示不应挂到地物上（会跟着星球转）")
			failed += 1
		if not prompt.visible:
			printerr("站在猴面包树下应显示 A 提示")
			failed += 1
		if absf(prompt.global_rotation) > 0.01:
			printerr("A 提示应保持屏幕朝向，实际 rotation=%s" % prompt.global_rotation)
			failed += 1
		var crown := baobab.to_global(Vector2(0.0, WorldConstants.INTERACT_PROMPT_LOCAL_Y))
		if prompt.global_position.distance_to(crown) > 2.5:
			printerr("A 提示应跟在树冠上，期望 %s 实际 %s" % [crown, prompt.global_position])
			failed += 1
		planet.teleport_player(fposmod(baobab.rotation + 0.08, TAU))
		await process_frame
		if absf(prompt.global_rotation) > 0.01:
			printerr("星球转过后 A 提示仍应不旋转，实际 %s" % prompt.global_rotation)
			failed += 1
		crown = baobab.to_global(Vector2(0.0, WorldConstants.INTERACT_PROMPT_LOCAL_Y))
		if prompt.global_position.distance_to(crown) > 2.5:
			printerr("星球转过后 A 提示应跟着树走，期望 %s 实际 %s" % [crown, prompt.global_position])
			failed += 1
		var prompt_material := prompt.material as ShaderMaterial
		if prompt_material == null or prompt_material.shader == null:
			printerr("A 提示应挂长按进度 ShaderMaterial")
			failed += 1
		elif prompt_material.shader.resource_path != "res://ui/interact_prompt.gdshader":
			printerr("A 提示 shader 应为 interact_prompt.gdshader")
			failed += 1
		else:
			prompt.hold_fill_ratio = 0.4
			var fill_ratio: float = prompt_material.get_shader_parameter("fill_ratio")
			if not is_equal_approx(fill_ratio, prompt.hold_fill_ratio):
				printerr("A 提示长按进度应为 %s，实际 %s" % [prompt.hold_fill_ratio, fill_ratio])
				failed += 1
			prompt.hold_fill_ratio = 0.0
			fill_ratio = prompt_material.get_shader_parameter("fill_ratio")
			if not is_equal_approx(fill_ratio, 0.0):
				printerr("松开后 A 提示长按进度应归零，实际 %s" % fill_ratio)
				failed += 1

	if dialogue != null:
		var panel := dialogue.get_node("Panel") as Control
		if (
				not is_equal_approx(panel.anchor_top, 0.5)
				or not is_equal_approx(panel.anchor_bottom, 0.5)
		):
			printerr("对话框应锚在屏幕中间")
			failed += 1
		var viewport_height := float((scene.get_node(VIEWPORT_PATH) as SubViewport).size.y)
		var panel_center_y := panel.position.y + panel.size.y * 0.5
		var expected_center_below_midline := 16.0
		var expected_center_y := viewport_height * 0.5 + expected_center_below_midline
		if absf(panel_center_y - expected_center_y) > 1.0:
			printerr(
					"对话框应略低于屏幕中线，期望 y=%s 实际 %s"
					% [expected_center_y, panel_center_y]
			)
			failed += 1

	for dialogue_id in [&"baobab", &"baobab_shoot", &"rose"]:
		if DialogueCatalog.lines_for_id(dialogue_id).size() < 2:
			printerr("%s 对话至少两句" % dialogue_id)
			failed += 1

	var lines := DialogueCatalog.lines_for_id(&"baobab")
	if lines.size() >= 2 and dialogue != null:
		failed += await _check_typewriter_hold(scene, dialogue, lines)
		dialogue.close()
		if dialogue.is_open():
			printerr("close 后对话框应关闭")
			failed += 1

	print("  地物交互 / 叙事对话 OK")
	return failed

func _assert_focus(
	planet: Planet, target: SurfaceProp, dialogue_id: StringName, label: String
) -> int:
	planet.teleport_player(target.rotation)
	var failed := 0
	var found := planet.find_nearest_interactable()
	if found != target:
		printerr("站在%s旁应选中该地物，实际 %s" % [label, found])
		failed += 1
	if not target.is_interactable() or target.get_dialogue_id() != dialogue_id:
		printerr("%s 应为可交互且 dialogue_id=%s" % [label, dialogue_id])
		failed += 1
	return failed


func _check_typewriter_hold(
	scene: Node, dialogue: DialogueBox, lines: Array[DialogueLine]
) -> int:
	var failed := 0
	var body := dialogue.get_node("Panel/HBox/VBox/Body") as Label
	var timer := dialogue.get_node("Timer") as Timer
	var typewriter := dialogue.get_node("Typewriter") as AudioStreamPlayer
	var continue_triangle := dialogue.get_node("ContinueTriangle") as Control
	var first_text := lines[0].text
	var second_text := lines[1].text

	dialogue.play(lines)
	if not dialogue.is_open() or not dialogue.is_typing():
		printerr("play 后对话框应打开且处于打字机中")
		failed += 1
	if continue_triangle.visible:
		printerr("打字中不应显示继续三角")
		failed += 1
	if body.text != first_text:
		printerr("play 后应显示第一句")
		failed += 1

	var characters_before_hold := body.visible_characters
	dialogue.mark_holding(true)
	if not dialogue.is_typing():
		printerr("播放中按下应继续打字，而不是立刻结束")
		failed += 1
	if body.visible_characters >= body.get_total_character_count():
		printerr("播放中按下不应把当前句一次显示完")
		failed += 1
	if body.visible_characters != characters_before_hold:
		printerr("播放中按下不应立刻多出字")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("播放中按住应加速，wait_time=%s" % timer.wait_time)
		failed += 1
	if not is_equal_approx(typewriter.volume_db, DialogueBox.TYPEWRITER_FAST_VOLUME_DB):
		printerr("加速时音效应降低，volume_db=%s" % typewriter.volume_db)
		failed += 1

	dialogue.mark_holding(false)
	if not dialogue.is_typing() or body.text != first_text:
		printerr("播放中松开应恢复速度并留在当前句")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("松开后应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	if not is_equal_approx(typewriter.volume_db, DialogueBox.TYPEWRITER_VOLUME_DB):
		printerr("松开后音效应恢复，volume_db=%s" % typewriter.volume_db)
		failed += 1

	dialogue.mark_holding(true)
	if not await _await_dialogue_idle(dialogue):
		printerr("按住加速后打字机超时未结束")
		return failed + 1
	if not continue_triangle.visible:
		printerr("打字结束后应显示继续三角")
		failed += 1
	if not is_equal_approx(typewriter.volume_db, DialogueBox.TYPEWRITER_VOLUME_DB):
		printerr("打字结束后音效应恢复，volume_db=%s" % typewriter.volume_db)
		failed += 1
	dialogue.mark_holding(false)
	if not dialogue.is_open() or dialogue.is_typing() or body.text != first_text:
		printerr("按住直到结束再松开，不应进入下一句")
		failed += 1
	if not continue_triangle.visible:
		printerr("按住结束再松开后继续三角仍应显示")
		failed += 1

	await process_frame
	dialogue.mark_holding(true)
	if body.text != first_text or not dialogue.is_open() or dialogue.is_typing():
		printerr("播放结束后按下任意键不应进入下一句")
		failed += 1
	dialogue.mark_holding(false)
	if not dialogue.is_open() or body.text != second_text:
		printerr("播放结束后松开才应进入下一句")
		failed += 1
	if not dialogue.is_typing():
		printerr("进入下一句后应重新打字")
		failed += 1
	if continue_triangle.visible:
		printerr("进入下一句打字中不应显示继续三角")
		failed += 1

	if not await _await_dialogue_idle(dialogue):
		printerr("第二句打字机超时未结束")
		return failed + 1
	if not continue_triangle.visible:
		printerr("第二句打完应显示继续三角")
		failed += 1
	dialogue.mark_holding(true)
	if dialogue.is_open():
		printerr("最后一句按下后应立即关闭对话框")
		failed += 1
	dialogue.mark_holding(false)

	failed += await _check_typewriter_hold_through_line_then_release(scene, dialogue, lines)
	failed += await _check_typewriter_hold_follows_confirm_events(scene, dialogue, lines)
	return failed


func _check_typewriter_hold_through_line_then_release(
	scene: Node, dialogue: DialogueBox, lines: Array[DialogueLine]
) -> int:
	var failed := 0
	var body := dialogue.get_node("Panel/HBox/VBox/Body") as Label
	var continue_triangle := dialogue.get_node("ContinueTriangle") as Control
	var first_text := lines[0].text
	var second_text := lines[1].text

	dialogue.play(lines)
	scene._input(_interact_key_event(true))
	if not await _await_dialogue_idle(dialogue):
		printerr("按住直到打完超时")
		return failed + 1
	if body.text != first_text or dialogue.is_typing():
		printerr("按住直到打完应留在第一句")
		failed += 1
	scene._input(_interact_key_event(false))
	if not dialogue.is_open() or dialogue.is_typing() or body.text != first_text:
		printerr("按住直到打完再松开不应进入下一句")
		failed += 1
	if not continue_triangle.visible:
		printerr("按住直到打完再松开后继续三角仍应显示")
		failed += 1
	await process_frame
	scene._input(_interact_key_event(true))
	if body.text != first_text or dialogue.is_typing():
		printerr("打完后按下不应进入下一句")
		failed += 1
	scene._input(_interact_key_event(false))
	if not dialogue.is_open() or body.text != second_text:
		printerr("打完后松开再按再松开才应进入下一句")
		failed += 1
	dialogue.close()
	return failed


func _check_typewriter_hold_follows_confirm_events(
	scene: Node, dialogue: DialogueBox, lines: Array[DialogueLine]
) -> int:
	var failed := 0
	var timer := dialogue.get_node("Timer") as Timer
	var body := dialogue.get_node("Panel/HBox/VBox/Body") as Label
	var first_text := lines[0].text

	dialogue.play(lines)
	scene._input(_move_left_event(true))
	await process_frame
	if not dialogue.is_typing():
		printerr("按住移动打开对话后应仍在打字")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("按住移动不应加速打字机，wait_time=%s" % timer.wait_time)
		failed += 1

	scene._input(_interact_key_event(true))
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("按下确认键应加速，wait_time=%s" % timer.wait_time)
		failed += 1
	if body.visible_characters >= body.get_total_character_count():
		printerr("加速前当前句应尚未打完")
		failed += 1
	scene._input(_interact_key_event(false))
	if not dialogue.is_typing() or body.text != first_text:
		printerr("打字中松开确认键应继续打字并留在当前句")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("打字中松开确认键应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_move_left_event(false))
	dialogue.close()

	dialogue.play(lines)
	dialogue.mark_holding(true)
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("打开对话时仍按住确认键应立即加速，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_interact_key_event(false))
	if not dialogue.is_typing():
		printerr("打开后松开确认键应继续打字")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("打开后松开确认键应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	dialogue.close()

	failed += _check_typewriter_hold_restores_after_key_release(scene, dialogue, lines)
	return failed


func _check_typewriter_hold_restores_after_key_release(
	scene: Node, dialogue: DialogueBox, lines: Array[DialogueLine]
) -> int:
	var failed := 0
	var timer := dialogue.get_node("Timer") as Timer
	var body := dialogue.get_node("Panel/HBox/VBox/Body") as Label
	dialogue.play(lines)
	scene._input(_interact_key_event(true))
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("实体 Enter 按下应加速，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_interact_key_event(false))
	if not dialogue.is_typing():
		printerr("松开实体 Enter 后应继续打字")
		failed += 1
	if body.visible_characters >= body.get_total_character_count():
		printerr("松开实体 Enter 后当前句应尚未打完")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("松开实体 Enter 后应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	dialogue.close()

	failed += _check_typewriter_hold_joypad_confirm(scene, dialogue, lines)
	return failed


func _check_typewriter_hold_joypad_confirm(
	scene: Node, dialogue: DialogueBox, lines: Array[DialogueLine]
) -> int:
	var failed := 0
	var timer := dialogue.get_node("Timer") as Timer
	var body := dialogue.get_node("Panel/HBox/VBox/Body") as Label

	dialogue.play(lines)
	scene._input(_interact_joy_event(true))
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("手柄确认键按下应加速，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_interact_joy_event(false))
	if not dialogue.is_typing():
		printerr("松开手柄确认键后应继续打字")
		failed += 1
	if body.visible_characters >= body.get_total_character_count():
		printerr("松开手柄确认键后当前句应尚未打完")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("松开手柄确认键后应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	dialogue.close()

	dialogue.play(lines)
	scene._input(_interact_joy_event(true))
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("手柄确认键按下应加速，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_interact_joy_event(false))
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("松开手柄确认键后应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_interact_key_event(true))
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_FAST_INTERVAL):
		printerr("手柄松开后按住键盘应加速，wait_time=%s" % timer.wait_time)
		failed += 1
	scene._input(_interact_key_event(false))
	if not dialogue.is_typing():
		printerr("键盘松开后应继续打字")
		failed += 1
	if not is_equal_approx(timer.wait_time, DialogueBox.TYPEWRITER_INTERVAL):
		printerr("键盘松开后应恢复正常速度，wait_time=%s" % timer.wait_time)
		failed += 1
	dialogue.close()
	return failed


func _interact_key_event(pressed: bool) -> InputEventKey:
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.keycode = KEY_ENTER
	enter.pressed = pressed
	return enter


func _interact_joy_event(pressed: bool) -> InputEventJoypadButton:
	var joy_button := InputEventJoypadButton.new()
	joy_button.device = 0
	joy_button.button_index = JOY_BUTTON_A
	joy_button.pressed = pressed
	return joy_button


func _move_left_event(pressed: bool) -> InputEventKey:
	var move_left := InputEventKey.new()
	move_left.physical_keycode = KEY_A
	move_left.keycode = KEY_A
	move_left.pressed = pressed
	return move_left


func _await_dialogue_idle(dialogue: DialogueBox) -> bool:
	var deadline_msec := Time.get_ticks_msec() + 2000
	while dialogue.is_typing() and Time.get_ticks_msec() < deadline_msec:
		await process_frame
	return not dialogue.is_typing()


func _check_b612_story(scene: Node, planet: Planet) -> int:
	var failed := 0
	var story := scene.get_node("GameView/GameViewport/B612Story") as B612Story
	if story == null:
		printerr("找不到 B612Story")
		return 1
	if scene.get_node_or_null("GameView/GameViewport/B612Story/MigratoryFlock") == null:
		printerr("找不到 MigratoryFlock")
		failed += 1
	var camera := scene.get_node_or_null("GameView/GameViewport/GameCamera") as Camera2D
	if camera == null:
		printerr("找不到 GameCamera")
		return failed + 1
	if camera.anchor_mode != Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT:
		printerr("GameCamera 应固定左上，避免改变默认构图")
		failed += 1
	var player := scene.get_node(PLAYER_PATH) as Player
	var dialogue_body := story.dialogue.get_node("Panel/HBox/VBox/Body") as Label
	var fade_layer := story.get_node("FadeLayer") as CanvasLayer
	if fade_layer.layer >= story.dialogue.layer:
		printerr("开场淡入时对话框应叠在黑场之上")
		failed += 1
	story.skip_cinematics = false
	var fade_started_msec := Time.get_ticks_msec()
	story.start()
	if story.dialogue.is_open():
		printerr("黑屏淡入前玫瑰不应开口")
		failed += 1
	if story.get_node("%Dim").color.a < 0.99:
		printerr("开场应为黑屏")
		failed += 1
	if not story.is_blocking_input:
		printerr("淡入时应禁止输入")
		failed += 1
	if player.can_move_left or player.can_move_right:
		printerr("淡入时不应能走动")
		failed += 1
	planet.angular_velocity = 0.0
	Input.action_press("move_right")
	player._physics_process(0.2)
	Input.action_release("move_right")
	if absf(planet.angular_velocity) > 0.001:
		printerr("淡入时按右不应自转，角速度 %s" % planet.angular_velocity)
		failed += 1
	var rose_deadline_msec := fade_started_msec + 4000
	while (
			(
				not story.dialogue.is_open()
				or not dialogue_body.text.contains("我刚刚睡醒")
			)
			and Time.get_ticks_msec() < rose_deadline_msec
	):
		await process_frame
	var rose_delay_msec := Time.get_ticks_msec() - fade_started_msec
	if (
			not story.dialogue.is_open()
			or not dialogue_body.text.contains("我刚刚睡醒")
	):
		printerr("淡入一半时玫瑰应开始说话")
		failed += 1
	elif rose_delay_msec < 800:
		printerr("玫瑰开口过早，淡入仅 %d ms" % rose_delay_msec)
		failed += 1
	elif rose_delay_msec > 1800:
		printerr("玫瑰开口过晚，淡入已 %d ms" % rose_delay_msec)
		failed += 1
	var dim_alpha := (story.get_node("%Dim") as ColorRect).color.a
	if dim_alpha < 0.25 or dim_alpha > 0.75:
		printerr("玫瑰开口时黑场应淡入过半，实际 alpha=%s" % dim_alpha)
		failed += 1
	if not story.is_blocking_input:
		printerr("玫瑰开口后仍应禁止走动")
		failed += 1
	story.skip_cinematics = true
	await story.start()
	if story.get_node("%Dim").color.a > 0.01:
		printerr("跳过演出后开场黑场应已淡完")
		failed += 1
	if not story.has_finished_opening:
		printerr("开场结束后应罩上玻璃罩并可向右走")
		failed += 1
	if story.is_blocking_input:
		printerr("开场结束后应允许走动")
		failed += 1
	if not story._glass_globe().visible:
		printerr("开场罩上玻璃罩后才应拔苗")
		failed += 1
	if not player.can_move_right:
		printerr("罩上玻璃罩后应能向右走")
		failed += 1
	if player.can_move_left:
		printerr("开场应只能向右走")
		failed += 1
	planet.angular_velocity = 0.0
	Input.action_press("move_left")
	player._physics_process(0.2)
	Input.action_release("move_left")
	if planet.angular_velocity < -0.001:
		printerr("开场按左不应移动，角速度 %s" % planet.angular_velocity)
		failed += 1
	planet.angular_velocity = 0.0
	Input.action_press("move_right")
	player._physics_process(0.2)
	var opening_right_velocity := planet.angular_velocity
	Input.action_release("move_right")
	planet.angular_velocity = 0.0
	var opening_move_speed_scale := player.move_speed_scale
	player.move_speed_scale = 1.0
	Input.action_press("move_right")
	player._physics_process(0.2)
	var full_right_velocity := planet.angular_velocity
	Input.action_release("move_right")
	planet.angular_velocity = 0.0
	player.move_speed_scale = opening_move_speed_scale
	if opening_right_velocity <= 0.001:
		printerr("开场按右应能走动")
		failed += 1
	elif opening_right_velocity >= full_right_velocity * 0.95:
		printerr(
				"开场右移应更慢，开场角速度 %s，全速 %s"
				% [opening_right_velocity, full_right_velocity]
		)
		failed += 1
	story.try_first_sunset_narration(SkyPhase.NOON_PHASE)
	story.try_first_sunset_narration(SkyPhase.SUNSET_PHASE)
	await process_frame
	if not story.has_crossed_sunset:
		printerr("跨过日落应进入日落段")
		failed += 1
	if story.is_blocking_input:
		printerr("日落后应恢复输入")
		failed += 1
	if not player.can_move_left or not player.can_move_right:
		printerr("触发日落后应能左右移动")
		failed += 1
	if not is_equal_approx(player.move_speed_scale, 1.0):
		printerr("触发日落后移速应恢复，实际 %s" % player.move_speed_scale)
		failed += 1
	var shoots: Array[SurfaceProp] = []
	var volcanoes: Array[SurfaceProp] = []
	var rose: SurfaceProp = null
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.BAOBAB:
				shoots.append(prop)
			SurfaceProp.Kind.VOLCANO:
				volcanoes.append(prop)
			SurfaceProp.Kind.ROSE:
				rose = prop
	if shoots.size() != WorldConstants.BAOBAB_COUNT:
		printerr("剧情嫩芽数应为 %d" % WorldConstants.BAOBAB_COUNT)
		return failed + 1
	if not story.accepts_interact(shoots[0]):
		printerr("拔苗段应选中嫩芽")
		failed += 1
	var interaction := scene.get_node("GameView/GameViewport/Interaction") as Interaction
	var prompt := scene.get_node("GameView/GameViewport/InteractPrompt") as InteractPrompt
	var overhead := story.overhead
	var overhead_body := overhead.get_node("Body") as Label
	const FIRST_PULL_OVERHEAD := "小王子的星球总会长出猴面包树"
	story.skip_cinematics = false
	if not is_equal_approx(story.interact_hold_seconds(shoots[0]), B612Story.PULL_SHOOT_HOLD_SECONDS):
		printerr(
				"拔苗长按时长应为 %s，实际 %s"
				% [B612Story.PULL_SHOOT_HOLD_SECONDS, story.interact_hold_seconds(shoots[0])]
		)
		failed += 1
	if not is_zero_approx(story.interact_hold_seconds(rose)):
		printerr("拔苗段玫瑰不应长按")
		failed += 1
	interaction.set_process(false)
	planet.teleport_player(shoots[0].rotation)
	planet.angular_velocity = 0.0
	interaction._process(0.0)
	if not prompt.visible:
		printerr("拔苗时应显示 A 提示")
		failed += 1
	Input.action_release("interact")
	Input.action_press("interact")
	interaction._process(0.0)
	Input.action_release("interact")
	interaction._process(0.0)
	if shoots[0].is_consumed:
		printerr("点按不应拔掉嫩芽")
		failed += 1
	if not is_equal_approx(prompt.hold_fill_ratio, 0.0):
		printerr("点按松开后进度应归零，实际 %s" % prompt.hold_fill_ratio)
		failed += 1
	Input.action_press("interact")
	interaction._process(B612Story.PULL_SHOOT_HOLD_SECONDS * 0.5)
	if absf(prompt.hold_fill_ratio - 0.5) > 0.01:
		printerr("长按一半时进度应接近一半，实际 %s" % prompt.hold_fill_ratio)
		failed += 1
	if shoots[0].is_consumed:
		printerr("长按未结束时嫩芽不应消失")
		failed += 1
	Input.action_press("move_right")
	player._physics_process(0.2)
	Input.action_release("move_right")
	if absf(planet.angular_velocity) > 0.001:
		printerr("长按拔苗时应不能走动，角速度 %s" % planet.angular_velocity)
		failed += 1
	Input.action_release("interact")
	interaction._process(0.0)
	if not is_equal_approx(prompt.hold_fill_ratio, 0.0):
		printerr("长按中途松开后进度应归零，实际 %s" % prompt.hold_fill_ratio)
		failed += 1
	if shoots[0].is_consumed:
		printerr("长按中途松开不应拔掉嫩芽")
		failed += 1
	Input.action_press("interact")
	interaction._process(B612Story.PULL_SHOOT_HOLD_SECONDS)
	Input.action_release("interact")
	if not shoots[0].is_consumed or shoots[0].visible:
		printerr("长按结束后嫩芽应立即消失")
		failed += 1
	if not story.is_blocking_input:
		printerr("拔苗头顶叙事时应禁用输入")
		failed += 1
	var overhead_start_deadline_msec := Time.get_ticks_msec() + 3000
	while (
			not overhead.visible
			and Time.get_ticks_msec() < overhead_start_deadline_msec
	):
		if shoots[0].visible:
			printerr("头顶叙事出现前嫩芽应保持消失")
			failed += 1
			break
		await process_frame
	if not overhead.visible or overhead_body.text != FIRST_PULL_OVERHEAD:
		printerr(
				"拔掉后应播放头顶叙事，实际 %s"
				% overhead_body.text
		)
		failed += 1
	var pull_deadline_msec := Time.get_ticks_msec() + 15000
	while story.is_blocking_input and Time.get_ticks_msec() < pull_deadline_msec:
		await process_frame
	if story.is_blocking_input:
		printerr("拔苗头顶叙事超时")
		failed += 1
	interaction.set_process(true)
	story.skip_cinematics = true

	for shoot in shoots:
		if shoot.is_consumed:
			continue
		if not story.try_handle_interact(shoot):
			printerr("拔苗段应能拔除嫩芽")
			failed += 1
		if not shoot.is_consumed or shoot.visible:
			printerr("拔掉的嫩芽应消耗并隐藏")
			failed += 1
	if story.accepts_interact(shoots[0]):
		printerr("已拔嫩芽不应再交互")
		failed += 1
	for volcano in volcanoes:
		if volcano.is_interactable() or story.accepts_interact(volcano):
			printerr("火山只作为装饰，不应可交互")
			failed += 1
		for child in volcano.get_children():
			var smoke := child as CPUParticles2D
			if smoke != null and not smoke.emitting:
				printerr("装饰火山应继续冒烟")
				failed += 1
	var glass_globe := rose.get_node("GlassGlobe") as Sprite2D
	if not glass_globe.visible:
		printerr("告别前玻璃罩应还在")
		failed += 1
	if not story.accepts_interact(rose):
		printerr("拔完苗后玫瑰应可告别")
		failed += 1
	if story.flock.visible:
		printerr("候鸟不应提前出现")
		failed += 1
	if not story.try_handle_interact(rose):
		printerr("拔完苗后应按 A 告别")
		failed += 1
	if glass_globe.visible:
		printerr("告别后应拿掉玻璃罩")
		failed += 1
	if player.modulate.a > 0.01:
		printerr("离星后小王子应消失")
		failed += 1
	if story.get_node("%Dim").color.a < 0.99:
		printerr("离星后应淡出到黑场")
		failed += 1
	if story.get_node("%Epilogue").text.is_empty():
		printerr("黑场应留下星球名")
		failed += 1
	story.flock.arrive_from_offscreen(player.global_position)
	await process_frame
	var viewport_rect := (scene.get_node(VIEWPORT_PATH) as SubViewport).get_visible_rect()
	var inner_rect := viewport_rect.grow(-12.0)
	for child in story.flock.get_children():
		var bird := child as Sprite2D
		if bird == null:
			continue
		if inner_rect.has_point(bird.global_position):
			printerr("候鸟起始应在屏外，实际 %s" % bird.global_position)
			failed += 1
			break
	if failed == 0:
		print("  B612 故乡剧情 OK")
	return failed
