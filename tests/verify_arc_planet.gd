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
	"res://planet/white_lavender_puff_frames.png",
	"res://planet/body.png",
	"res://planet/starfield.png",
	"res://planet/day_sky.png",
	"res://ui/portraits/prince.png",
	"res://ui/portraits/rose.png",
	"res://ui/portraits/king.png",
	"res://planet/amber_mottled_disk.png",
	"res://ui/portraits/slumped_wine_drinker.png",
	"res://planet/ink_gold_ledger_disk.png",
	"res://ui/portraits/hunched_ledger_merchant.png",
	"res://ui/portraits/black_coat_lamplighter.png",
	"res://planet/cream_ink_parchment_disk.png",
	"res://ui/portraits/gray_beard_parchment_scholar.png",
]

const REQUIRED_OTHER_ASSETS: Array[String] = [
	"res://ui/typewriter.wav",
	"res://ui/fonts/fusion-pixel-8px-zh_hans.woff2",
	"res://ui/fonts/fusion-pixel-10px-zh_hans.woff2",
	"res://audio/the_one_who_stands_distant.ogg",
	"res://audio/i_want_to_go_home.ogg",
	"res://audio/narrow_cpenta_toy_waltz.ogg",
	"res://audio/sparse_ledger_tally.ogg",
	"res://audio/rapid_lamp_duty_tick.ogg",
	"res://audio/dry_folio_rest.ogg",
	"res://audio/muffled_dirt_thud_a.wav",
	"res://audio/muffled_dirt_thud_b.wav",
	"res://audio/dry_grass_rustle_a.wav",
	"res://audio/dry_grass_rustle_b.wav",
	"res://audio/thin_rat_squeak.wav",
]

func _init() -> void:
	call_deferred(&"_run_tests")

func _run_tests() -> void:
	var failed := 0
	failed += _check_constants()
	failed += _check_static_assets()
	failed += _check_no_legacy()
	failed += _check_tscn_editor_visible()
	failed += _check_king_scene_resource_uids()
	failed += _check_drunkard_scene_resource_uids()
	failed += _check_merchant_scene_resource_uids()
	failed += _check_lamplighter_scene_resource_uids()
	failed += _check_geographer_scene_resource_uids()
	failed += _check_input_map()
	failed += await _check_main_story_starts_with_sky_ready()
	failed += await _check_story_not_active_before_planet_ready()
	failed += await _check_scene_and_mechanics()
	failed += await _check_footsteps()
	failed += await _check_standalone_planet_scenes()
	failed += await _check_b612_depart_lift_halfway_overhead()
	failed += await _check_king_chapter()
	failed += await _check_b612_departed_travels_to_king()
	failed += await _check_drunkard_chapter()
	failed += await _check_king_departed_travels_to_drunkard()
	failed += await _check_merchant_chapter()
	failed += await _check_drunkard_departed_travels_to_merchant()
	failed += await _check_lamplighter_chapter()
	failed += await _check_merchant_departed_travels_to_lamplighter()
	failed += await _check_geographer_chapter()
	failed += await _check_lamplighter_departed_travels_to_geographer()
	if failed == 0:
		print("[verify_arc_planet] 全部通过")
		quit(0)
	else:
		printerr("[verify_arc_planet] 失败项数：%d" % failed)
		quit(1)


func _is_editable_texture(tex: Texture2D) -> bool:
	return (
			tex is EditableTexture
			or tex.get_script() == preload("res://addons/godot_editable_texture/editable_texture.gd")
	)


func _texture_image(tex: Texture2D) -> Image:
	var image := tex.get_image()
	if image != null and not image.is_empty():
		return image
	var inner := tex.get("_texture") as ImageTexture
	if inner != null:
		return inner.get_image()
	return image


func _instantiate_scene(scene_path: String) -> Node:
	return (load(scene_path) as PackedScene).instantiate()


func _scene_sprite_texture(scene_path: String, node_path: NodePath) -> Texture2D:
	var scene := _instantiate_scene(scene_path)
	var node := scene.get_node_or_null(node_path)
	var tex: Texture2D = null
	if node is Sprite2D:
		tex = (node as Sprite2D).texture
	elif node is CPUParticles2D:
		tex = (node as CPUParticles2D).texture
	scene.free()
	return tex


func _planet_body_texture(scene_path: String) -> Texture2D:
	var planet := _instantiate_scene(scene_path) as Planet
	var tex := planet.body_texture
	planet.free()
	return tex


func _migratory_bird_texture() -> Texture2D:
	var shell := _instantiate_scene("res://planet/planet_run_shell.tscn")
	var flock := shell.get_node("GameView/GameViewport/Story/MigratoryFlock") as MigratoryFlock
	var tex := flock.bird_texture
	shell.free()
	return tex


func _butterfly_sheet_texture() -> Texture2D:
	var butterfly := _instantiate_scene("res://planet/butterfly.tscn") as AnimatedSprite2D
	var atlas := butterfly.sprite_frames.get_frame_texture(&"default", 0) as AtlasTexture
	var tex: Texture2D = atlas.atlas if atlas != null else null
	butterfly.free()
	return tex


func _check_constants() -> int:
	var failed := 0
	if WorldConstants.VOLCANO_COUNT != 3:
		printerr("VOLCANO_COUNT 应为 3，实际 %d" % WorldConstants.VOLCANO_COUNT)
		failed += 1
	if WorldConstants.BAOBAB_COUNT != 9:
		printerr("BAOBAB_COUNT 应为 9，实际 %d" % WorldConstants.BAOBAB_COUNT)
		failed += 1
	if WorldConstants.FLORA_COUNT != 75:
		printerr("FLORA_COUNT 应为 75，实际 %d" % WorldConstants.FLORA_COUNT)
		failed += 1
	if WorldConstants.BUTTERFLY_COUNT != 8:
		printerr("BUTTERFLY_COUNT 应为 8，实际 %d" % WorldConstants.BUTTERFLY_COUNT)
		failed += 1
	if WorldConstants.DRUNKARD_BOTTLE_COUNT != 17:
		printerr("DRUNKARD_BOTTLE_COUNT 应为 17，实际 %d" % WorldConstants.DRUNKARD_BOTTLE_COUNT)
		failed += 1
	if WorldConstants.LAMPLIGHTER_PLANET_RADIUS >= WorldConstants.PLANET_RADIUS:
		printerr("点灯人星球应比故乡更小")
		failed += 1
	if WorldConstants.LAMPLIGHTER_STAR_ROTATION_SPEED <= WorldConstants.STAR_ROTATION_SPEED * 20.0:
		printerr("点灯人昼夜自转应明显快于默认星空")
		failed += 1
	if WorldConstants.GEOGRAPHER_REPORT_STACK_COUNT != 3:
		printerr("书房报告堆应为 3，实际 %d" % WorldConstants.GEOGRAPHER_REPORT_STACK_COUNT)
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
		WorldConstants.KING_SPRITE_WIDTH < 16 or WorldConstants.KING_SPRITE_WIDTH > 28
		or WorldConstants.KING_SPRITE_HEIGHT < 18 or WorldConstants.KING_SPRITE_HEIGHT > 32
	):
		printerr(
			"KING_SPRITE 应约 20×24，实际 %dx%d"
			% [WorldConstants.KING_SPRITE_WIDTH, WorldConstants.KING_SPRITE_HEIGHT]
		)
		failed += 1
	if WorldConstants.KING_PLANET_RADIUS <= WorldConstants.PLANET_RADIUS:
		printerr("KING_PLANET_RADIUS 应比 B612 大一圈")
		failed += 1
	if WorldConstants.KING_PLANET_RADIUS > WorldConstants.PLANET_RADIUS * 1.35:
		printerr("KING_PLANET_RADIUS 不应大到第二座能逛的星球，实际 %s" % WorldConstants.KING_PLANET_RADIUS)
		failed += 1
	if WorldConstants.KING_AUDIENCE_KEEP_AWAY_ARC <= WorldConstants.INTERACT_RANGE_PX / WorldConstants.KING_PLANET_RADIUS:
		printerr("觐见禁区应大于贴身交互距离")
		failed += 1
	if WorldConstants.KING_AUDIENCE_KEEP_AWAY_ARC >= WorldConstants.VISIBLE_HALF_ARC:
		printerr("禁区过大则会看不见王座")
		failed += 1
	if WorldConstants.KING_DISTANT_VOICE_ARC <= WorldConstants.VISIBLE_HALF_ARC:
		printerr("国王声音应在看见人之前")
		failed += 1
	if (
		WorldConstants.GOLD_SPIRED_THRONE_HEIGHT < 48
		or WorldConstants.GOLD_SPIRED_THRONE_HEIGHT > 96
	):
		printerr("王座应明显高于国王，实际高 %d" % WorldConstants.GOLD_SPIRED_THRONE_HEIGHT)
		failed += 1
	if (
		WorldConstants.RAT_SPRITE_WIDTH < 8 or WorldConstants.RAT_SPRITE_WIDTH > 14
		or WorldConstants.RAT_SPRITE_HEIGHT < 6 or WorldConstants.RAT_SPRITE_HEIGHT > 12
	):
		printerr(
			"RAT_SPRITE 应约 10×8，实际 %dx%d"
			% [WorldConstants.RAT_SPRITE_WIDTH, WorldConstants.RAT_SPRITE_HEIGHT]
		)
		failed += 1
	if (
		WorldConstants.DARK_SOIL_BURROW_WIDTH != 12
		or WorldConstants.DARK_SOIL_BURROW_HEIGHT != 8
	):
		printerr(
			"DARK_SOIL_BURROW 应为 12×8，实际 %dx%d"
			% [WorldConstants.DARK_SOIL_BURROW_WIDTH, WorldConstants.DARK_SOIL_BURROW_HEIGHT]
		)
		failed += 1
	if WorldConstants.FLORA_SPRITE_SIZE < 12 or WorldConstants.FLORA_SPRITE_SIZE > 20:
		printerr("FLORA_SPRITE_SIZE 应约 12~18，实际 %d" % WorldConstants.FLORA_SPRITE_SIZE)
		failed += 1
	if WorldConstants.FLORA_VARIANT_COUNT < 4:
		printerr("FLORA_VARIANT_COUNT 应覆盖草与其他植物，实际 %d" % WorldConstants.FLORA_VARIANT_COUNT)
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
		var loaded_resource: Resource = load(path)
		if loaded_resource == null:
			printerr("无法加载资源：%s" % path)
			failed += 1
			continue
		if not path.ends_with(".ogg"):
			continue
		var ogg := loaded_resource as AudioStreamOggVorbis
		if ogg == null:
			printerr("配乐应为 Ogg：%s" % path)
			failed += 1
		elif ogg.get_length() < 30.0:
			printerr("%s 配乐过短：%s 秒" % [path, ogg.get_length()])
			failed += 1
		elif not ogg.loop:
			printerr("%s 配乐应循环" % path)
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
	var king_body: Texture2D = _planet_body_texture("res://planet/king.tscn")
	if king_body != null:
		var king_diameter: int = int(ceil(WorldConstants.KING_PLANET_RADIUS)) * 2
		if king_body.get_width() != king_diameter or king_body.get_height() != king_diameter:
			printerr(
				"国王星球圆盘应为 %dx%d，实际 %dx%d"
				% [king_diameter, king_diameter, king_body.get_width(), king_body.get_height()]
			)
			failed += 1
		elif not _is_editable_texture(king_body):
			printerr("国王星球圆盘应为场景内 EditableTexture")
			failed += 1
	var amber_body: Texture2D = load("res://planet/amber_mottled_disk.png") as Texture2D
	if amber_body != null:
		var amber_diameter: int = int(ceil(WorldConstants.PLANET_RADIUS)) * 2
		if amber_body.get_width() != amber_diameter or amber_body.get_height() != amber_diameter:
			printerr(
				"amber_mottled_disk.png 应为 %dx%d，实际 %dx%d"
				% [amber_diameter, amber_diameter, amber_body.get_width(), amber_body.get_height()]
			)
			failed += 1
	var ledger_body: Texture2D = load("res://planet/ink_gold_ledger_disk.png") as Texture2D
	if ledger_body != null:
		var ledger_diameter: int = int(ceil(WorldConstants.PLANET_RADIUS)) * 2
		if ledger_body.get_width() != ledger_diameter or ledger_body.get_height() != ledger_diameter:
			printerr(
				"ink_gold_ledger_disk.png 应为 %dx%d，实际 %dx%d"
				% [ledger_diameter, ledger_diameter, ledger_body.get_width(), ledger_body.get_height()]
			)
			failed += 1
	var parchment_body: Texture2D = load("res://planet/cream_ink_parchment_disk.png") as Texture2D
	if parchment_body != null:
		var parchment_diameter: int = int(ceil(WorldConstants.PLANET_RADIUS)) * 2
		if (
				parchment_body.get_width() != parchment_diameter
				or parchment_body.get_height() != parchment_diameter
		):
			printerr(
				"cream_ink_parchment_disk.png 应为 %dx%d，实际 %dx%d"
				% [
					parchment_diameter,
					parchment_diameter,
					parchment_body.get_width(),
					parchment_body.get_height(),
				]
			)
			failed += 1
	var ash_body: Texture2D = _planet_body_texture("res://planet/lamplighter.tscn")
	if ash_body != null:
		var ash_diameter: int = int(ceil(WorldConstants.LAMPLIGHTER_PLANET_RADIUS)) * 2
		if ash_body.get_width() != ash_diameter or ash_body.get_height() != ash_diameter:
			printerr(
				"点灯人星球圆盘应为 %dx%d，实际 %dx%d"
				% [ash_diameter, ash_diameter, ash_body.get_width(), ash_body.get_height()]
			)
			failed += 1
		elif not _is_editable_texture(ash_body):
			printerr("点灯人星球圆盘应为场景内 EditableTexture")
			failed += 1
	var file_sprite_checks: Array = [
		[
			"res://planet/white_lavender_puff_frames.png",
			WorldConstants.CLOUD_FRAME_WIDTH * WorldConstants.CLOUD_FRAME_COLUMNS,
			WorldConstants.CLOUD_FRAME_HEIGHT * WorldConstants.CLOUD_FRAME_ROWS,
		],
		["res://ui/portraits/prince.png", 32, 32],
		["res://ui/portraits/rose.png", 32, 32],
		["res://ui/portraits/king.png", 32, 32],
		["res://ui/portraits/slumped_wine_drinker.png", 32, 32],
		["res://ui/portraits/hunched_ledger_merchant.png", 32, 32],
		["res://ui/portraits/black_coat_lamplighter.png", 32, 32],
		["res://ui/portraits/gray_beard_parchment_scholar.png", 32, 32],
	]
	for item in file_sprite_checks:
		var tex: Texture2D = load(item[0]) as Texture2D
		if tex == null:
			continue
		if tex.get_width() != int(item[1]) or tex.get_height() != int(item[2]):
			printerr(
				"%s 尺寸应为 %dx%d，实际 %dx%d"
				% [item[0], item[1], item[2], tex.get_width(), tex.get_height()]
			)
			failed += 1
	var embedded_sprite_checks: Array = [
		[
			"火山",
			_scene_sprite_texture("res://planet/b612.tscn", "Surface/Volcano"),
			WorldConstants.VOLCANO_SPRITE_SIZE * WorldConstants.VOLCANO_VARIANT_COUNT,
			WorldConstants.VOLCANO_SPRITE_SIZE,
		],
		["火山烟", _scene_sprite_texture("res://planet/b612.tscn", "Surface/Volcano/VolcanoSmoke"), 8, 8],
		[
			"猴面包树",
			_scene_sprite_texture("res://planet/b612.tscn", "Surface/Baobab"),
			WorldConstants.BAOBAB_SPRITE_SIZE * WorldConstants.BAOBAB_VARIANT_COUNT,
			WorldConstants.BAOBAB_SPRITE_SIZE,
		],
		[
			"地表植物",
			_scene_sprite_texture("res://planet/b612.tscn", "Surface/Flora6"),
			WorldConstants.FLORA_SPRITE_SIZE * WorldConstants.FLORA_VARIANT_COUNT,
			WorldConstants.FLORA_SPRITE_SIZE,
		],
		["玫瑰", _scene_sprite_texture("res://planet/b612.tscn", "Surface/Rose"), WorldConstants.ROSE_SPRITE_SIZE, WorldConstants.ROSE_SPRITE_SIZE],
		["玻璃罩", _scene_sprite_texture("res://planet/b612.tscn", "Surface/Rose/GlassGlobe"), 24, 24],
		["国王", _scene_sprite_texture("res://planet/king.tscn", "Surface/King"), WorldConstants.KING_SPRITE_WIDTH, WorldConstants.KING_SPRITE_HEIGHT],
		["金尖顶王座", _scene_sprite_texture("res://planet/king.tscn", "Surface/Throne"), WorldConstants.GOLD_SPIRED_THRONE_WIDTH, WorldConstants.GOLD_SPIRED_THRONE_HEIGHT],
		["红披风", _scene_sprite_texture("res://planet/king.tscn", "Surface/Cape"), WorldConstants.CRIMSON_CAPE_SPREAD_WIDTH, WorldConstants.CRIMSON_CAPE_SPREAD_HEIGHT],
		["展开诏书", _scene_sprite_texture("res://planet/king.tscn", "Surface/EdictL"), WorldConstants.UNROLLED_PARCHMENT_WIDTH, WorldConstants.UNROLLED_PARCHMENT_HEIGHT],
		["划痕边框", _scene_sprite_texture("res://planet/king.tscn", "Surface/Border1"), WorldConstants.SCRATCHED_BORDER_LINES_WIDTH, WorldConstants.SCRATCHED_BORDER_LINES_HEIGHT],
		["浅色爪印", _scene_sprite_texture("res://planet/king.tscn", "Surface/RatTrace1"), WorldConstants.PALE_PAW_PRINTS_WIDTH, WorldConstants.PALE_PAW_PRINTS_HEIGHT],
		["老鼠", _scene_sprite_texture("res://planet/king.tscn", "Surface/Rat"), WorldConstants.RAT_SPRITE_WIDTH, WorldConstants.RAT_SPRITE_HEIGHT],
		["土洞", _scene_sprite_texture("res://planet/king.tscn", "Surface/RatHole"), WorldConstants.DARK_SOIL_BURROW_WIDTH, WorldConstants.DARK_SOIL_BURROW_HEIGHT],
		[
			"小王子",
			_scene_sprite_texture("res://planet/planet_run_shell.tscn", "GameView/GameViewport/Player"),
			WorldConstants.PLAYER_SPRITE_WIDTH * WorldConstants.PLAYER_SPRITE_FRAME_COUNT,
			WorldConstants.PLAYER_SPRITE_HEIGHT,
		],
		["交互提示", _scene_sprite_texture("res://planet/planet_run_shell.tscn", "GameView/GameViewport/InteractPrompt"), 13, 13],
		["棕玻璃瓶", _scene_sprite_texture("res://planet/drunkard.tscn", "Surface/Bottle1"), WorldConstants.BROWN_GLASS_BOTTLE_WIDTH, WorldConstants.BROWN_GLASS_BOTTLE_HEIGHT],
		["酒鬼", _scene_sprite_texture("res://planet/drunkard.tscn", "Surface/Drunkard"), WorldConstants.SLUMPED_WINE_DRINKER_WIDTH, WorldConstants.SLUMPED_WINE_DRINKER_HEIGHT],
		["商人", _scene_sprite_texture("res://planet/merchant.tscn", "Surface/Merchant"), WorldConstants.HUNCHED_LEDGER_MERCHANT_WIDTH, WorldConstants.HUNCHED_LEDGER_MERCHANT_HEIGHT],
		["金星玻璃罐", _scene_sprite_texture("res://planet/merchant.tscn", "Surface/StarJar"), WorldConstants.GOLD_STAR_GLASS_JAR_WIDTH, WorldConstants.GOLD_STAR_GLASS_JAR_HEIGHT],
		["点灯人", _scene_sprite_texture("res://planet/lamplighter.tscn", "Surface/Lamplighter"), WorldConstants.BLACK_COAT_LAMPLIGHTER_WIDTH, WorldConstants.BLACK_COAT_LAMPLIGHTER_HEIGHT],
		[
			"路灯",
			_scene_sprite_texture("res://planet/lamplighter.tscn", "Surface/StreetLamp"),
			WorldConstants.BLACK_POST_STREET_LAMP_WIDTH * WorldConstants.BLACK_POST_STREET_LAMP_FRAME_COUNT,
			WorldConstants.BLACK_POST_STREET_LAMP_HEIGHT,
		],
		[
			"地理学家",
			_scene_sprite_texture("res://planet/geographer.tscn", "Surface/Geographer"),
			WorldConstants.GRAY_BEARD_PARCHMENT_SCHOLAR_WIDTH,
			WorldConstants.GRAY_BEARD_PARCHMENT_SCHOLAR_HEIGHT,
		],
		[
			"报告堆",
			_scene_sprite_texture("res://planet/geographer.tscn", "Surface/ReportStackA"),
			WorldConstants.STACKED_CREAM_INK_PAGES_WIDTH,
			WorldConstants.STACKED_CREAM_INK_PAGES_HEIGHT,
		],
		["候鸟", _migratory_bird_texture(), 16, 8],
		["蝴蝶图集", _butterfly_sheet_texture(), 8, 3],
	]
	for item in embedded_sprite_checks:
		var tex: Texture2D = item[1]
		if tex == null:
			printerr("缺少内嵌贴图：%s" % item[0])
			failed += 1
			continue
		if not _is_editable_texture(tex):
			printerr("%s 应为 EditableTexture" % item[0])
			failed += 1
		if tex.get_width() != int(item[2]) or tex.get_height() != int(item[3]):
			printerr(
				"%s 尺寸应为 %dx%d，实际 %dx%d"
				% [item[0], item[2], item[3], tex.get_width(), tex.get_height()]
			)
			failed += 1
	if FileAccess.file_exists("res://planet/sky.gd") or FileAccess.file_exists("res://planet/clouds.gd"):
		printerr("sky.gd / clouds.gd 应已收进 planet.tscn 子节点 builtin")
		failed += 1
	if FileAccess.file_exists("res://planet/butterfly.gd"):
		printerr("butterfly.gd 应已收进 butterfly.tscn 根节点 builtin")
		failed += 1
	var volcano_tex := _scene_sprite_texture("res://planet/b612.tscn", "Surface/Volcano")
	if volcano_tex != null:
		var volcano_img := _texture_image(volcano_tex)
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
	var flora_tex := _scene_sprite_texture("res://planet/b612.tscn", "Surface/Flora6")
	if flora_tex != null:
		var flora_img := _texture_image(flora_tex)
		var found_leaf := false
		var found_cool_dry_grass := false
		for pixel_y in range(flora_img.get_height()):
			for pixel_x in range(flora_img.get_width()):
				var pixel := flora_img.get_pixel(pixel_x, pixel_y)
				if pixel.a < 0.5:
					continue
				if pixel.g > pixel.r and pixel.g > pixel.b:
					found_leaf = true
				if pixel.b > pixel.r + 0.08 and pixel.g > pixel.r and pixel.s > 0.2:
					found_cool_dry_grass = true
		if not found_leaf:
			printerr("地表植物贴图应含绿色叶片")
			failed += 1
		if not found_cool_dry_grass:
			printerr("地表植物贴图应含冷青等非草色变体")
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
		"res://journey/main.tscn",
		"res://planet/planet_run_shell.tscn",
		"res://planet/planet.tscn",
		"res://planet/b612.tscn",
		"res://planet/king.tscn",
		"res://planet/vain.tscn",
		"res://planet/drunkard.tscn",
		"res://planet/merchant.tscn",
		"res://planet/lamplighter.tscn",
		"res://planet/geographer.tscn",
		"res://planet/butterfly.tscn",
		"res://ui/dialogue_box.tscn",
		"res://ui/overhead_typewriter.tscn",
	]:
		var src := FileAccess.get_file_as_string(path)
		if src.contains("visible = false"):
			printerr("%s 不应在 tscn 写 visible = false（编辑器要能看见，运行时脚本再关）" % path)
			failed += 1
	print("  tscn 编辑器可见 OK")
	return failed


func _check_king_scene_resource_uids() -> int:
	var failed := 0
	var uid_and_path := RegEx.new()
	uid_and_path.compile("uid=\"(uid://[^\"]+)\" path=\"([^\"]+)\"")
	var king_scene := FileAccess.get_file_as_string("res://planet/king.tscn")
	for match_ in uid_and_path.search_all(king_scene):
		var declared_uid := match_.get_string(1)
		var resource_path := match_.get_string(2)
		var canonical_uid := ResourceUID.id_to_text(
				ResourceLoader.get_resource_uid(resource_path)
		)
		if declared_uid != canonical_uid:
			printerr(
					"king.tscn 资源 UID 应与文件一致：%s 声明 %s，文件 %s"
					% [resource_path, declared_uid, canonical_uid]
			)
			failed += 1
	var zenith_header := FileAccess.get_file_as_string(
			"res://planet/king_zenith_gradient.tres"
	).get_slice("\n", 0)
	var zenith_canonical := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid("res://planet/king_zenith_gradient.tres")
	)
	if not zenith_header.contains(zenith_canonical):
		printerr(
				"king_zenith_gradient.tres 头 UID 应为 %s"
				% zenith_canonical
		)
		failed += 1
	if failed == 0:
		print("  国王场景资源 UID 与文件一致 OK")
	return failed


func _check_drunkard_scene_resource_uids() -> int:
	var failed := 0
	var uid_and_path := RegEx.new()
	uid_and_path.compile("uid=\"(uid://[^\"]+)\" path=\"([^\"]+)\"")
	var drunkard_scene := FileAccess.get_file_as_string("res://planet/drunkard.tscn")
	for match_ in uid_and_path.search_all(drunkard_scene):
		var declared_uid := match_.get_string(1)
		var resource_path := match_.get_string(2)
		var canonical_uid := ResourceUID.id_to_text(
				ResourceLoader.get_resource_uid(resource_path)
		)
		if declared_uid != canonical_uid:
			printerr(
					"drunkard.tscn 资源 UID 应与文件一致：%s 声明 %s，文件 %s"
					% [resource_path, declared_uid, canonical_uid]
			)
			failed += 1
	var zenith_header := FileAccess.get_file_as_string(
			"res://planet/amber_evening_zenith_gradient.tres"
	).get_slice("\n", 0)
	var zenith_canonical := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid("res://planet/amber_evening_zenith_gradient.tres")
	)
	if not zenith_header.contains(zenith_canonical):
		printerr(
				"amber_evening_zenith_gradient.tres 头 UID 应为 %s"
				% zenith_canonical
		)
		failed += 1
	if failed == 0:
		print("  酒鬼场景资源 UID 与文件一致 OK")
	return failed


func _check_merchant_scene_resource_uids() -> int:
	var failed := 0
	var uid_and_path := RegEx.new()
	uid_and_path.compile("uid=\"(uid://[^\"]+)\" path=\"([^\"]+)\"")
	var merchant_scene := FileAccess.get_file_as_string("res://planet/merchant.tscn")
	for match_ in uid_and_path.search_all(merchant_scene):
		var declared_uid := match_.get_string(1)
		var resource_path := match_.get_string(2)
		var canonical_uid := ResourceUID.id_to_text(
				ResourceLoader.get_resource_uid(resource_path)
		)
		if declared_uid != canonical_uid:
			printerr(
					"merchant.tscn 资源 UID 应与文件一致：%s 声明 %s，文件 %s"
					% [resource_path, declared_uid, canonical_uid]
			)
			failed += 1
	var zenith_header := FileAccess.get_file_as_string(
			"res://planet/ink_night_zenith_gradient.tres"
	).get_slice("\n", 0)
	var zenith_canonical := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid("res://planet/ink_night_zenith_gradient.tres")
	)
	if not zenith_header.contains(zenith_canonical):
		printerr(
				"ink_night_zenith_gradient.tres 头 UID 应为 %s"
				% zenith_canonical
		)
		failed += 1
	if failed == 0:
		print("  商人场景资源 UID 与文件一致 OK")
	return failed


func _check_lamplighter_scene_resource_uids() -> int:
	var failed := 0
	var uid_and_path := RegEx.new()
	uid_and_path.compile("uid=\"(uid://[^\"]+)\" path=\"([^\"]+)\"")
	var lamplighter_scene := FileAccess.get_file_as_string("res://planet/lamplighter.tscn")
	for match_ in uid_and_path.search_all(lamplighter_scene):
		var declared_uid := match_.get_string(1)
		var resource_path := match_.get_string(2)
		var canonical_uid := ResourceUID.id_to_text(
				ResourceLoader.get_resource_uid(resource_path)
		)
		if declared_uid != canonical_uid:
			printerr(
					"lamplighter.tscn 资源 UID 应与文件一致：%s 声明 %s，文件 %s"
					% [resource_path, declared_uid, canonical_uid]
			)
			failed += 1
	var zenith_header := FileAccess.get_file_as_string(
			"res://planet/gray_day_night_zenith_gradient.tres"
	).get_slice("\n", 0)
	var zenith_canonical := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid("res://planet/gray_day_night_zenith_gradient.tres")
	)
	if not zenith_header.contains(zenith_canonical):
		printerr(
				"gray_day_night_zenith_gradient.tres 头 UID 应为 %s"
				% zenith_canonical
		)
		failed += 1
	if failed == 0:
		print("  点灯人场景资源 UID 与文件一致 OK")
	return failed


func _check_geographer_scene_resource_uids() -> int:
	var failed := 0
	var uid_and_path := RegEx.new()
	uid_and_path.compile("uid=\"(uid://[^\"]+)\" path=\"([^\"]+)\"")
	var geographer_scene := FileAccess.get_file_as_string("res://planet/geographer.tscn")
	for match_ in uid_and_path.search_all(geographer_scene):
		var declared_uid := match_.get_string(1)
		var resource_path := match_.get_string(2)
		var canonical_uid := ResourceUID.id_to_text(
				ResourceLoader.get_resource_uid(resource_path)
		)
		if declared_uid != canonical_uid:
			printerr(
					"geographer.tscn 资源 UID 应与文件一致：%s 声明 %s，文件 %s"
					% [resource_path, declared_uid, canonical_uid]
			)
			failed += 1
	var zenith_header := FileAccess.get_file_as_string(
			"res://planet/parchment_study_zenith_gradient.tres"
	).get_slice("\n", 0)
	var zenith_canonical := ResourceUID.id_to_text(
			ResourceLoader.get_resource_uid("res://planet/parchment_study_zenith_gradient.tres")
	)
	if not zenith_header.contains(zenith_canonical):
		printerr(
				"parchment_study_zenith_gradient.tres 头 UID 应为 %s"
				% zenith_canonical
		)
		failed += 1
	if failed == 0:
		print("  地理学家场景资源 UID 与文件一致 OK")
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


func _assert_playing_music(scene: Node, meta_name: String, label: String) -> int:
	return _assert_playing_stream(
			scene,
			scene.get_node("Config").get_meta(meta_name) as AudioStream,
			"%s应播放配乐 %s" % [label, meta_name]
	)


func _assert_playing_stream(scene: Node, expected: AudioStream, mismatch_message: String) -> int:
	var music := scene.get_node("%Music")
	if music.playing_stream != expected:
		printerr(mismatch_message)
		return 1
	var playing := music.get_node("Playing") as AudioStreamPlayer
	var incoming := music.get_node("Incoming") as AudioStreamPlayer
	if not playing.playing and not incoming.playing:
		printerr("%s（配乐应在播放）" % mismatch_message)
		return 1
	return 0


func _check_main_story_starts_with_sky_ready() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	scene.travel_to_next_planet = false
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	root.add_child(scene)
	await process_frame
	await process_frame
	var story := scene.get_node("%Story") as B612Story
	var player := scene.get_node(PLAYER_PATH) as Player
	if story.planet.sky == null:
		printerr("main 开场 Story.start 时 planet.sky 不应为空")
		failed += 1
	if not is_equal_approx(player.move_speed_scale, 0.8):
		printerr(
				"B612 开场应已 _prepare_start，move_speed_scale=%s"
				% player.move_speed_scale
		)
		failed += 1
	if failed == 0:
		print("  main 开场等星球 ready 后再读天空 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_story_not_active_before_planet_ready() -> int:
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	scene.travel_to_next_planet = false
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	var viewport := scene.get_node("GameView/GameViewport")
	var story := viewport.get_node("Story") as B612Story
	var planet := viewport.get_node("Planet") as Planet
	var watcher := Node.new()
	watcher.name = "PlanetReadyOrderWatcher"
	var activated_before_planet_ready: Array[bool] = [false]
	watcher.ready.connect(
			func() -> void:
				if story.is_active and not planet.is_node_ready():
					activated_before_planet_ready[0] = true
	)
	viewport.add_child(watcher)
	viewport.move_child(story, 0)
	viewport.move_child(watcher, 1)
	viewport.move_child(planet, 2)
	root.add_child(scene)
	await process_frame
	await process_frame
	var failed := 0
	if activated_before_planet_ready[0]:
		printerr("Story 不应在 Planet ready 前 is_active（_process 会读到空 sky）")
		failed += 1
	if not planet.is_node_ready():
		printerr("开场后 Planet 应已 ready")
		failed += 1
	elif not is_equal_approx(
			(scene.get_node(PLAYER_PATH) as Player).move_speed_scale,
			0.8
	):
		printerr("B612 开场应在 Planet ready 后 _prepare_start")
		failed += 1
	if failed == 0:
		print("  Story 在 Planet ready 后才 is_active OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_scene_and_mechanics() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	scene.travel_to_next_planet = false
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame

	var opening_planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	if opening_planet == null or opening_planet.scene_file_path != "res://planet/b612.tscn":
		printerr(
				"主场景开局应为 b612.tscn，实际 %s"
				% (opening_planet.scene_file_path if opening_planet != null else "null")
		)
		failed += 1
	if scene.get_node_or_null("%KingStory") as KingStory == null:
		printerr("主场景应有 KingStory")
		failed += 1
	failed += _assert_playing_music(scene, "home_day_music", "开局")
	if (
			(scene.get_node("Config").get_meta("home_day_music") as Resource).resource_path
			!= "res://audio/the_one_who_stands_distant.ogg"
	):
		printerr("开场配乐应为 The one who stands Distant")
		failed += 1

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
	elif not player.flip_h:
		printerr("B612 开场小王子默认应面向左边")
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
		if planet.flora_angles.size() != WorldConstants.FLORA_COUNT:
			printerr(
				"地表植物数量应为 %d，实际 %d"
				% [WorldConstants.FLORA_COUNT, planet.flora_angles.size()]
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
		var flora_props: Array[SurfaceProp] = []
		var shared_flora_material: ShaderMaterial = null
		var flora_shader := load("res://planet/flora_sway.gdshader") as Shader
		if flora_shader == null:
			printerr("无法加载 flora_sway.gdshader")
			failed += 1
		elif (
			not flora_shader.code.contains("MODEL_MATRIX")
			or not flora_shader.code.contains("VERTEX")
		):
			printerr("植株 sway shader 应按世界坐标驱动顶点位移")
			failed += 1
		for prop in planet.surface_props:
			if prop.kind != SurfaceProp.Kind.FLORA:
				continue
			flora_props.append(prop)
			if prop.variant < 0 or prop.variant >= WorldConstants.FLORA_VARIANT_COUNT:
				printerr("地表植物变体越界：%d" % prop.variant)
				failed += 1
			if prop.frame != prop.variant:
				printerr(
					"地表植物 %s 的 frame 应与 variant 一致，实际 frame=%d variant=%d"
					% [prop.name, prop.frame, prop.variant]
				)
				failed += 1
			if prop.hframes != WorldConstants.FLORA_VARIANT_COUNT:
				printerr(
					"地表植物 %s hframes 应为 %d，实际 %d"
					% [prop.name, WorldConstants.FLORA_VARIANT_COUNT, prop.hframes]
				)
				failed += 1
			if prop.texture == null or not _is_editable_texture(prop.texture):
				printerr("地表植物 %s 应使用场景内嵌 flora 贴图" % prop.name)
				failed += 1
			if prop.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
				printerr("地表植物 %s 应为 Nearest 过滤" % prop.name)
				failed += 1
			if prop.is_interactable() or prop.get_dialogue_id() != &"":
				printerr("地表植物 %s 只作为装饰，不应可交互" % prop.name)
				failed += 1
			var flora_material := prop.material as ShaderMaterial
			if (
				flora_material == null
				or flora_material.shader == null
				or flora_material.shader.resource_path != "res://planet/flora_sway.gdshader"
			):
				printerr("地表植物 %s 应挂载 flora_sway ShaderMaterial" % prop.name)
				failed += 1
			elif shared_flora_material == null:
				shared_flora_material = flora_material
			elif flora_material != shared_flora_material:
				printerr("地表植物应共享同一 sway 材质")
				failed += 1
		if flora_props.size() != WorldConstants.FLORA_COUNT:
			printerr(
				"地表植物节点数应为 %d，实际 %d"
				% [WorldConstants.FLORA_COUNT, flora_props.size()]
			)
			failed += 1
		const FLORA_CLOSE_NEIGHBOR_ARC_PX := 4.5
		const FLORA_CLUSTER_JOIN_ARC_PX := 6.0
		const FLORA_MIN_CLUSTERED_RATIO := 0.55
		const FLORA_MIN_CLUSTER_COUNT := 6
		const FLORA_MAX_CLUSTER_COUNT := 18
		const FLORA_ROSE_CLEARANCE_RAD := 0.18
		var sorted_flora_angles: Array[float] = planet.flora_angles.duplicate()
		sorted_flora_angles.sort()
		var flora_count := sorted_flora_angles.size()
		var close_neighbor_count := 0
		var flora_cluster_count := 0
		var close_neighbor_rad := FLORA_CLOSE_NEIGHBOR_ARC_PX / planet.radius
		var cluster_join_rad := FLORA_CLUSTER_JOIN_ARC_PX / planet.radius
		for flora_index in flora_count:
			var flora_angle: float = sorted_flora_angles[flora_index]
			if absf(angle_difference(flora_angle, planet.rose_angle)) < FLORA_ROSE_CLEARANCE_RAD:
				printerr("地表植物不应贴住玫瑰")
				failed += 1
			var previous_angle: float = sorted_flora_angles[flora_index - 1]
			var next_angle: float = sorted_flora_angles[(flora_index + 1) % flora_count]
			var nearest_gap := minf(
					absf(angle_difference(flora_angle, previous_angle)),
					absf(angle_difference(flora_angle, next_angle)),
			)
			if nearest_gap < close_neighbor_rad:
				close_neighbor_count += 1
			if absf(angle_difference(flora_angle, next_angle)) > cluster_join_rad:
				flora_cluster_count += 1
		var clustered_ratio := float(close_neighbor_count) / float(flora_count)
		if clustered_ratio < FLORA_MIN_CLUSTERED_RATIO:
			printerr(
				"地表植物应成簇分布，近邻成簇比例应为至少 %s，实际 %s"
				% [FLORA_MIN_CLUSTERED_RATIO, clustered_ratio]
			)
			failed += 1
		if (
			flora_cluster_count < FLORA_MIN_CLUSTER_COUNT
			or flora_cluster_count > FLORA_MAX_CLUSTER_COUNT
		):
			printerr(
				"地表植物应分成多簇，簇数应在 %d~%d，实际 %d"
				% [FLORA_MIN_CLUSTER_COUNT, FLORA_MAX_CLUSTER_COUNT, flora_cluster_count]
			)
			failed += 1
		var expected_props: int = (
			1 + WorldConstants.VOLCANO_COUNT + WorldConstants.BAOBAB_COUNT
			+ WorldConstants.FLORA_COUNT
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
		failed += _check_butterflies(planet)
		if not is_equal_approx(planet.player_angle, 0.75):
			printerr("云层检查后 player_angle 应恢复为 0.75")
			failed += 1
		if planet.star_rotation_speed <= 0.0:
			printerr("star_rotation_speed 应大于 0（星空相对星球自转）")
			failed += 1
		if not is_equal_approx(sky.star_rotation_speed, planet.star_rotation_speed):
			printerr("Sky.star_rotation_speed 应与 Planet 导出一致")
			failed += 1
		if not sky.is_self_rotating:
			printerr("默认星空应相对星球自转")
			failed += 1
		else:
			var rotation_before_self: float = sky.rotation
			sky._process(10.0)
			if is_equal_approx(sky.rotation, rotation_before_self):
				printerr("默认星空应相对星球自转")
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

		failed += _check_ui_pixel_fonts(scene)
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


func _check_butterflies(planet: Planet) -> int:
	var failed := 0
	var original_player_angle := planet.player_angle
	var butterflies: Array = []
	for child in planet.surface.get_children():
		if child.scene_file_path == "res://planet/butterfly.tscn":
			butterflies.append(child)
	if butterflies.size() != WorldConstants.BUTTERFLY_COUNT:
		printerr(
				"蝴蝶数量应为 %d，实际 %d"
				% [WorldConstants.BUTTERFLY_COUNT, butterflies.size()]
		)
		failed += 1
	if butterflies.is_empty():
		planet.teleport_player(original_player_angle)
		return failed + 1
	var packed_scene_path := "res://planet/butterfly.tscn"
	var opening_guide = null
	for butterfly in butterflies:
		if butterfly.scene_file_path != packed_scene_path:
			printerr("蝴蝶 %s 应实例化 butterfly.tscn" % butterfly.name)
			failed += 1
		if butterfly.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			printerr("蝴蝶 %s 应为 Nearest 过滤" % butterfly.name)
			failed += 1
		if butterfly.position.length() < planet.radius:
			printerr(
					"蝴蝶 %s 应在地表外，半径 %s 星球 %s"
					% [butterfly.name, butterfly.position.length(), planet.radius]
			)
			failed += 1
		if (
				absf(angle_difference(
						atan2(butterfly.position.x, -butterfly.position.y),
						butterfly._home_orbital_angle
				))
				> 0.25
		):
			printerr("蝴蝶 %s 应待在家园附近" % butterfly.name)
			failed += 1
		if not butterfly.is_playing():
			printerr("蝴蝶 %s 应在播放振翅动画" % butterfly.name)
			failed += 1
		if butterfly.guide_target_local_position != Vector2.ZERO:
			opening_guide = butterfly
			var tscn_home_position: Vector2 = Vector2(
					sin(butterfly._home_orbital_angle),
					-cos(butterfly._home_orbital_angle),
			) * butterfly._home_orbit_radius
			if butterfly.position.distance_to(tscn_home_position) > 0.02:
				printerr(
						"引导前 %s 应停在 tscn 坐标 %s，实际 %s"
						% [butterfly.name, tscn_home_position, butterfly.position]
				)
				failed += 1
			var held_position: Vector2 = butterfly.position
			butterfly._process(0.8)
			if butterfly.position.distance_to(held_position) > 0.02:
				printerr("引导前 %s 不应离开 tscn 坐标" % butterfly.name)
				failed += 1
			continue
		var position_before: Vector2 = butterfly.position
		butterfly._process(0.8)
		if butterfly.position.distance_to(position_before) < 0.05:
			printerr("蝴蝶 %s 应飞离原位" % butterfly.name)
			failed += 1
		if butterfly.position.length() < planet.radius:
			printerr("蝴蝶 %s 飞行后仍应在地表外" % butterfly.name)
			failed += 1
	if opening_guide == null:
		printerr("应有一只开场引导蝴蝶")
		failed += 1
	else:
		if opening_guide.name != "Butterfly3":
			printerr("开场引导应为 Butterfly3，实际 %s" % opening_guide.name)
			failed += 1
		if opening_guide.modulate.a > 0.01:
			printerr("Butterfly3 开场应透明")
			failed += 1
		if opening_guide.guide_target_local_position.distance_to(Vector2(92, -38)) > 0.5:
			printerr(
					"Butterfly3 引导目标应为 (92, -38)，实际 %s"
					% opening_guide.guide_target_local_position
			)
			failed += 1
		opening_guide.modulate.a = 0.4
		opening_guide._guide_flight_progress = 0.0
		opening_guide._elapsed_seconds = 0.0
		opening_guide._process(1.0)
		if opening_guide._guide_flight_progress > 0.001:
			printerr("淡入未完成时 Butterfly3 不应开始飞向目标")
			failed += 1
		opening_guide.modulate.a = 1.0
		opening_guide._guide_flight_progress = 0.0
		opening_guide._elapsed_seconds = 0.0
		var guide_target_orbital_angle := atan2(
				opening_guide.guide_target_local_position.x,
				-opening_guide.guide_target_local_position.y,
		)
		var orbital_span := absf(angle_difference(
				opening_guide._home_orbital_angle,
				guide_target_orbital_angle,
		))
		opening_guide._process(1.0)
		var expected_guide_progress := (
				WorldConstants.PLAYER_SPEED
				/ (orbital_span * WorldConstants.PLANET_RADIUS)
		)
		if absf(opening_guide._guide_flight_progress - expected_guide_progress) > 0.02:
			printerr(
					"引导飞速应等于行走速度 %s px/s，进度期望 %s 实际 %s"
					% [
						WorldConstants.PLAYER_SPEED,
						expected_guide_progress,
						opening_guide._guide_flight_progress,
					]
			)
			failed += 1
		opening_guide._guide_flight_progress = 1.0
		opening_guide._elapsed_seconds = (PI - 0.6) / 1.4
		opening_guide._process(0.0)
		if (
				opening_guide.position.distance_to(
						opening_guide.guide_target_local_position
				)
				> 0.5
		):
			printerr(
					"引导结束应到达 %s，实际 %s"
					% [opening_guide.guide_target_local_position, opening_guide.position]
			)
			failed += 1
		opening_guide._elapsed_seconds = 0.6
		var guided_position_before_bob: Vector2 = opening_guide.position
		opening_guide._process(0.0)
		if opening_guide.position.is_equal_approx(guided_position_before_bob):
			printerr("引导飞行时应保留上下浮动")
			failed += 1
		if (
				opening_guide.position.distance_to(
						opening_guide.guide_target_local_position
				)
				> 4.0
		):
			printerr("上下浮动应仍靠近引导目标")
			failed += 1
		opening_guide._guide_flight_progress = 0.0
		opening_guide._elapsed_seconds = 0.0
		opening_guide.modulate.a = 0.0
		opening_guide.position = Vector2(
				sin(opening_guide._home_orbital_angle),
				-cos(opening_guide._home_orbital_angle),
		) * opening_guide._home_orbit_radius
		opening_guide.rotation = opening_guide._home_orbital_angle
	for _step_index in 24:
		var fell_inside_planet := false
		for butterfly in butterflies:
			if butterfly.guide_target_local_position != Vector2.ZERO:
				continue
			butterfly._process(0.25)
			if butterfly.position.length() < planet.radius:
				printerr("蝴蝶 %s 盘旋时落到了地表内" % butterfly.name)
				failed += 1
				fell_inside_planet = true
				break
		if fell_inside_planet:
			break
	var sample = butterflies[0]
	var sample_orbital_angle := atan2(sample.position.x, -sample.position.y)
	planet.teleport_player(sample_orbital_angle)
	sample._process(0.0)
	if not sample.visible:
		printerr("弧顶处的蝴蝶应可见")
		failed += 1
	if sample.z_index < 90:
		printerr("弧顶处的蝴蝶应叠在草地前，z_index=%d" % sample.z_index)
		failed += 1
	planet.teleport_player(fposmod(sample_orbital_angle + PI, TAU))
	sample._process(0.0)
	if sample.visible:
		printerr("背面的蝴蝶应隐藏")
		failed += 1
	planet.teleport_player(original_player_angle)
	print("  草地蝴蝶盘旋 / 显隐 OK")
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


func _check_ui_pixel_fonts(scene: Node) -> int:
	var failed := 0
	var dialogue := scene.get_node("GameView/GameViewport/DialogueBox") as DialogueBox
	var overhead := scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	var epilogue := scene.get_node("%Epilogue") as Label
	var dialogue_font_path := "res://ui/fonts/fusion-pixel-10px-zh_hans.woff2"
	var narrative_font_path := "res://ui/fonts/fusion-pixel-8px-zh_hans.woff2"
	failed += _assert_label_pixel_font(
			dialogue.get_node("%Speaker") as Label,
			dialogue_font_path,
			10,
			"对话说话人",
	)
	failed += _assert_label_pixel_font(
			dialogue.get_node("%Body") as Label,
			dialogue_font_path,
			10,
			"对话正文",
	)
	failed += _assert_label_pixel_font(
			overhead.get_node("%Body") as Label,
			narrative_font_path,
			8,
			"头顶叙事",
	)
	failed += _assert_label_pixel_font(
			epilogue,
			narrative_font_path,
			8,
			"结尾叙事",
	)
	print("  对话 10px / 头顶叙事 8px OK")
	return failed


func _assert_label_pixel_font(
		label: Label,
		expected_font_path: String,
		expected_font_size: int,
		label_name: String,
) -> int:
	var failed := 0
	var font_size: int = label.get("theme_override_font_sizes/font_size")
	if font_size != expected_font_size:
		printerr("%s 字号应为 %d，实际 %s" % [label_name, expected_font_size, font_size])
		failed += 1
	var font: Font = label.get("theme_override_fonts/font")
	if font == null or font.resource_path != expected_font_path:
		var actual_path := font.resource_path if font != null else "null"
		printerr("%s 字体应为 %s，实际 %s" % [label_name, expected_font_path, actual_path])
		failed += 1
	return failed


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
	var flora: SurfaceProp = null
	for prop in planet.surface_props:
		if prop.kind == SurfaceProp.Kind.FLORA:
			flora = prop
			break
	if flora == null:
		printerr("场景中没有地表植物")
		failed += 1
	else:
		if flora.is_interactable():
			printerr("地表植物只作为装饰，不应可交互")
			failed += 1
		planet.teleport_player(flora.rotation)
		if planet.find_nearest_interactable() == flora:
			printerr("站在地表植物旁不应选中植物")
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

	if dialogue != null and rose != null:
		failed += await _check_dialogue_portrait_sides(planet, dialogue, rose)

	print("  地物交互 / 叙事对话 OK")
	return failed


func _check_dialogue_portrait_sides(
		planet: Planet,
		dialogue: DialogueBox,
		rose: SurfaceProp,
) -> int:
	var failed := 0
	var prince_portrait_path := "res://ui/portraits/prince.png"
	var rose_portrait_path := "res://ui/portraits/rose.png"
	Input.action_release("interact")

	dialogue.play(DialogueCatalog.lines_for_id(&"rose"))
	failed += _assert_dialogue_portrait_side(
			dialogue, prince_portrait_path, true, "小王子旁白"
	)
	dialogue.play_line(
			DialogueLine.new(
					DialogueCatalog.ROSE_SPEAKER, "开口", DialogueCatalog.ROSE_PORTRAIT
			)
	)
	failed += _assert_dialogue_portrait_side(
			dialogue, rose_portrait_path, false, "玫瑰开口"
	)
	dialogue.close()

	dialogue.play(DialogueCatalog.lines_for_id(&"baobab"))
	failed += _assert_dialogue_portrait_side(
			dialogue, prince_portrait_path, true, "树旁白"
	)
	dialogue.close()

	planet.teleport_player(rose.rotation)
	await process_frame
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")
	if not dialogue.is_open():
		printerr("按确认应打开对话")
		failed += 1
	else:
		failed += _assert_dialogue_portrait_side(
				dialogue, prince_portrait_path, true, "交互玫瑰旁白"
		)
	dialogue.close()
	return failed


func _assert_dialogue_portrait_side(
		dialogue: DialogueBox,
		resource_path: String,
		portrait_on_left: bool,
		label: String,
) -> int:
	var failed := 0
	var portrait := dialogue.get_node("%Portrait") as TextureRect
	var row := dialogue.get_node("%ContentRow") as HBoxContainer
	var speaker := dialogue.get_node("%Speaker") as Label
	if portrait.texture == null or portrait.texture.resource_path != resource_path:
		printerr("%s 头像应为 %s" % [label, resource_path])
		failed += 1
	var portrait_index := portrait.get_index()
	if portrait_on_left and portrait_index != 0:
		printerr("%s 头像应在左侧，实际 index=%s" % [label, portrait_index])
		failed += 1
	if not portrait_on_left and portrait_index != row.get_child_count() - 1:
		printerr("%s 头像应在右侧，实际 index=%s" % [label, portrait_index])
		failed += 1
	var expected_alignment := (
			HORIZONTAL_ALIGNMENT_LEFT if portrait_on_left
			else HORIZONTAL_ALIGNMENT_RIGHT
	)
	if speaker.horizontal_alignment != expected_alignment:
		printerr("%s 说话人应对齐到头像一侧" % label)
		failed += 1
	var panel := dialogue.get_node("%Panel") as Control
	const expected_aligned_inset := 4.0
	const expected_shrunk_inset := expected_aligned_inset + 32.0
	var expected_offset_left := (
			expected_aligned_inset if portrait_on_left
			else expected_shrunk_inset
	)
	var expected_offset_right := -(
			expected_shrunk_inset if portrait_on_left
			else expected_aligned_inset
	)
	if (
			not is_equal_approx(panel.offset_left, expected_offset_left)
			or not is_equal_approx(panel.offset_right, expected_offset_right)
	):
		printerr(
				"%s 对话框应变窄并贴齐头像一侧，实际 left=%s right=%s"
				% [label, panel.offset_left, panel.offset_right]
		)
		failed += 1
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
	var body := dialogue.get_node("%Body") as Label
	var timer := dialogue.get_node("Timer") as Timer
	var typewriter := dialogue.get_node("Typewriter") as AudioStreamPlayer
	var continue_triangle := dialogue.get_node("%ContinueTriangle") as Control
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
	var body := dialogue.get_node("%Body") as Label
	var continue_triangle := dialogue.get_node("%ContinueTriangle") as Control
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
	var body := dialogue.get_node("%Body") as Label
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
	var body := dialogue.get_node("%Body") as Label
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
	var body := dialogue.get_node("%Body") as Label

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
	var story := scene.get_node("GameView/GameViewport/Story") as B612Story
	if story == null:
		printerr("找不到 B612 Story")
		return 1
	if scene.get_node_or_null("GameView/GameViewport/Story/MigratoryFlock") == null:
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
	var rose := planet.get_node("Surface/Rose") as SurfaceProp
	var dialogue_body := story.dialogue.get_node("%Body") as Label
	var fade_layer := story.get_node("FadeLayer") as CanvasLayer
	if fade_layer.layer >= story.dialogue.layer:
		printerr("开场淡入时对话框应叠在黑场之上")
		failed += 1
	planet.teleport_player(planet.spawn_angle)
	if player.global_position.x <= rose.global_position.x:
		printerr("出生点小王子应在玫瑰右边")
		failed += 1
	var scarf := player.get_node("Scarf") as Scarf
	player.flip_h = false
	var settle_delta := 1.0 / 60.0
	for _step_index in 48:
		scarf._physics_process(settle_delta)
	story.skip_cinematics = false
	var fade_started_msec := Time.get_ticks_msec()
	story.start()
	if not player.flip_h:
		printerr("开场小王子应面向左边")
		failed += 1
	var neck := scarf.simulated_positions[0]
	var tip := scarf.simulated_positions[Scarf.POINT_COUNT - 1]
	if tip.x <= neck.x:
		printerr("开场围巾应在右边，neck=%s tip=%s" % [neck, tip])
		failed += 1
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
	var measure_star_self_rotation := func(delta_seconds: float) -> float:
		var rotation_before: float = planet.sky.rotation
		planet.sky._process(delta_seconds)
		return angle_difference(rotation_before, planet.sky.rotation)
	if planet.sky.is_self_rotating:
		printerr("罩玻璃罩前星空不应自转")
		failed += 1
	elif absf(measure_star_self_rotation.call(10.0)) > 0.0001:
		printerr("罩玻璃罩前星空不应自转")
		failed += 1
	if story.dialogue.is_open() and dialogue_body.text.contains("我刚刚睡醒"):
		failed += _assert_dialogue_portrait_side(
				story.dialogue,
				"res://ui/portraits/rose.png",
				false,
				"开场玫瑰开口",
		)
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
	if not planet.sky.is_self_rotating:
		printerr("罩上玻璃罩后星空应开始自转")
		failed += 1
	elif absf(measure_star_self_rotation.call(10.0)) < 0.0001:
		printerr("罩上玻璃罩后星空应开始自转")
		failed += 1
	var opening_guide := planet.get_node("%Butterfly3")
	if opening_guide.modulate.a > 0.01:
		printerr("跳过演出时 Butterfly3 不应开始引导")
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
	var music_before_b612_sunset := scene.get_node("%Music").playing_stream as AudioStream
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
	failed += _assert_playing_stream(scene, music_before_b612_sunset, "B612 日落不应切换配乐")
	var shoots: Array[SurfaceProp] = []
	var volcanoes: Array[SurfaceProp] = []
	var flora_props: Array[SurfaceProp] = []
	rose = null
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.BAOBAB:
				shoots.append(prop)
			SurfaceProp.Kind.VOLCANO:
				volcanoes.append(prop)
			SurfaceProp.Kind.FLORA:
				flora_props.append(prop)
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
	const FIRST_PULL_OVERHEAD := "B612总会长出猴面包树"
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
	for flora_prop in flora_props:
		if flora_prop.is_interactable() or story.accepts_interact(flora_prop):
			printerr("地表植物只作为装饰，不应可交互")
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
	if not planet.sky.is_self_rotating:
		printerr("拿掉玻璃罩后星空应继续自转")
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


func _drive_into_king_audience(planet: Planet) -> void:
	var side := planet.signed_angle_from_king()
	if is_zero_approx(side):
		side = 1.0
	var keep_away_edge := fposmod(
			planet.king_angle + signf(side) * (planet.audience_keep_away_arc + 0.04),
			TAU
	)
	planet.teleport_player(keep_away_edge)
	for step_index in 24:
		planet.move_player(-signf(side), 0.05)


func _assert_king_keep_away_and_facing(planet: Planet, king: SurfaceProp) -> int:
	var failed := 0
	var hidden_angle := fposmod(planet.king_angle + PI, TAU)
	planet.teleport_player(hidden_angle)
	if planet.is_king_visible_from_player() or king.visible:
		printerr("背面国王应出画")
		failed += 1
	var left_hidden := fposmod(
			planet.king_angle - WorldConstants.VISIBLE_HALF_ARC - 0.08,
			TAU
	)
	planet.teleport_player(left_hidden)
	if king.visible:
		printerr("从左靠近前国王应仍在屏外")
		failed += 1
	if not king.flip_h:
		printerr("屏外从左靠近应已面朝左")
		failed += 1
	planet.teleport_player(fposmod(planet.king_angle - 0.9, TAU))
	if not king.visible:
		printerr("从左靠近时应看见国王")
		failed += 1
	if not king.flip_h:
		printerr("从左看见时应面朝左")
		failed += 1
	planet.teleport_player(fposmod(planet.king_angle + 0.9, TAU))
	if not king.visible:
		printerr("测试穿帮：可见时直接换侧")
		failed += 1
	if not king.flip_h:
		printerr("转向必须在屏外完成，可见时不应转头")
		failed += 1
	planet.teleport_player(hidden_angle)
	var right_hidden := fposmod(
			planet.king_angle + WorldConstants.VISIBLE_HALF_ARC + 0.08,
			TAU
	)
	planet.teleport_player(right_hidden)
	if king.visible:
		printerr("从右靠近前国王应仍在屏外")
		failed += 1
	if king.flip_h:
		printerr("屏外从右靠近应已面朝右")
		failed += 1
	planet.teleport_player(fposmod(planet.king_angle + 0.9, TAU))
	if not king.visible or king.flip_h:
		printerr("从右看见时应面朝右")
		failed += 1
	var approach := fposmod(
			planet.king_angle + planet.audience_keep_away_arc + 0.12,
			TAU
	)
	planet.teleport_player(approach)
	planet.has_contacted_audience_keep_away = false
	for step_index in 24:
		planet.move_player(-1.0, 0.05)
	if absf(planet.signed_angle_from_king()) < planet.audience_keep_away_arc - 0.01:
		printerr("禁区应挡住走向王座脚下，实际偏移 %s" % planet.signed_angle_from_king())
		failed += 1
	if not planet.has_contacted_audience_keep_away:
		printerr("撞禁区应记下觐见接触")
		failed += 1
	planet.has_contacted_audience_keep_away = false
	planet.teleport_player(planet.spawn_angle)
	return failed


func _assert_king_romantic_palette(
		planet: Planet, throne: SurfaceProp, cape: SurfaceProp
) -> int:
	var failed := 0
	var body_image := (planet.body.texture as Texture2D).get_image()
	var blue_pixels := 0
	var warm_ground_pixels := 0
	var opaque_ground_pixels := 0
	for pixel_y in range(0, body_image.get_height(), 4):
		for pixel_x in range(0, body_image.get_width(), 4):
			var pixel := body_image.get_pixel(pixel_x, pixel_y)
			if pixel.a < 0.5:
				continue
			opaque_ground_pixels += 1
			if pixel.b > pixel.r + 0.04 and pixel.b > pixel.g - 0.08:
				blue_pixels += 1
			if pixel.r > pixel.b + 0.12 and pixel.s > 0.25:
				warm_ground_pixels += 1
	if opaque_ground_pixels == 0 or float(blue_pixels) / float(opaque_ground_pixels) < 0.45:
		printerr("国王星球地面应偏蓝")
		failed += 1
	if warm_ground_pixels > opaque_ground_pixels / 12:
		printerr("国王星球地面不应抢国王的暖色")
		failed += 1
	var king_zenith := (
			planet.sky.material as ShaderMaterial
	).get_shader_parameter("zenith_gradient") as GradientTexture1D
	if king_zenith == null:
		printerr("国王星球应有独立绿天渐变")
		failed += 1
	else:
		var noon := king_zenith.gradient.sample(SkyPhase.NOON_PHASE)
		if noon.g <= noon.r or noon.g <= noon.b:
			printerr("国王星球正午天空应偏绿，实际 %s" % noon)
			failed += 1
	if throne != null:
		var throne_image := (throne.texture as Texture2D).get_image()
		var found_warm := false
		for pixel_y in throne_image.get_height():
			for pixel_x in throne_image.get_width():
				var pixel := throne_image.get_pixel(pixel_x, pixel_y)
				if pixel.a < 0.5:
					continue
				if pixel.r > 0.7 and pixel.g > 0.45 and pixel.b < 0.55:
					found_warm = true
					break
			if found_warm:
				break
		if not found_warm:
			printerr("王座应为远景暖色锚点")
			failed += 1
	if cape != null:
		var cape_image := (cape.texture as Texture2D).get_image()
		var found_cape_warm := false
		for pixel_y in cape_image.get_height():
			for pixel_x in cape_image.get_width():
				var pixel := cape_image.get_pixel(pixel_x, pixel_y)
				if pixel.a < 0.5:
					continue
				if pixel.r > pixel.g + 0.08 and pixel.r > pixel.b:
					found_cape_warm = true
					break
			if found_cape_warm:
				break
		if not found_cape_warm:
			printerr("披风应为暖色地形")
			failed += 1
	return failed


func _check_king_chapter() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame

	var opening_planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	if opening_planet == null or opening_planet.scene_file_path != "res://planet/b612.tscn":
		printerr(
				"主场景开局应为 b612.tscn，实际 %s"
				% (opening_planet.scene_file_path if opening_planet != null else "null")
		)
		scene.queue_free()
		await process_frame
		return 1
	scene.travel_to_king_planet(false)
	await process_frame

	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var player: Player = scene.get_node_or_null(PLAYER_PATH) as Player
	var story := scene.get_node_or_null("%KingStory") as KingStory
	if planet == null or player == null or story == null:
		printerr("国王章缺少 Planet / Player / KingStory")
		scene.queue_free()
		await process_frame
		return 1
	if planet.scene_file_path != "res://planet/king.tscn":
		printerr("离星后星球应为 king.tscn，实际 %s" % planet.scene_file_path)
		failed += 1
	failed += _assert_playing_music(scene, "king_day_music", "换到国王星球")
	if player.planet != planet:
		printerr("换星后 Player 应绑定国王星球")
		failed += 1
	if (player.get_node("Scarf") as Scarf).planet != planet:
		printerr("换星后围巾应绑定国王星球")
		failed += 1
	if (scene.get_node("%Interaction") as Interaction).planet != planet:
		printerr("换星后 Interaction 应绑定国王星球")
		failed += 1
	if story.planet != planet:
		printerr("换星后 KingStory 应绑定国王星球")
		failed += 1

	var king: SurfaceProp = null
	var rat: SurfaceProp = null
	var rat_hole: SurfaceProp = null
	var throne: SurfaceProp = null
	var cape: SurfaceProp = null
	var edict: SurfaceProp = null
	var border_line: SurfaceProp = null
	var edict_count := 0
	var border_count := 0
	var rat_trace_count := 0
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.KING:
				king = prop
			SurfaceProp.Kind.RAT:
				rat = prop
			SurfaceProp.Kind.RAT_HOLE:
				rat_hole = prop
			SurfaceProp.Kind.THRONE:
				throne = prop
			SurfaceProp.Kind.CAPE:
				cape = prop
			SurfaceProp.Kind.EDICT:
				if edict == null:
					edict = prop
				edict_count += 1
			SurfaceProp.Kind.BORDER:
				if border_line == null:
					border_line = prop
				border_count += 1
			SurfaceProp.Kind.RAT_TRACE:
				rat_trace_count += 1
			SurfaceProp.Kind.ROSE, SurfaceProp.Kind.VOLCANO, SurfaceProp.Kind.BAOBAB, SurfaceProp.Kind.FLORA:
				printerr("国王星球不应有 B612 地物 %s" % prop.name)
				failed += 1
		if prop.kind == SurfaceProp.Kind.RAT or prop.kind == SurfaceProp.Kind.RAT_TRACE:
			if prop.is_interactable() or story.accepts_interact(prop):
				printerr("耗子本身不应可交互：%s" % prop.name)
				failed += 1
	if king == null:
		printerr("国王星球应有国王")
		failed += 1
	if rat == null:
		printerr("国王星球应有耗子")
		failed += 1
	if rat_hole == null:
		printerr("国王星球应有耗子洞")
		failed += 1
	if throne == null:
		printerr("国王星球应有高王座")
		failed += 1
	if cape == null:
		printerr("国王星球应有大披风")
		failed += 1
	if edict_count < 2:
		printerr("路上应有没人看的诏书，实际 %d" % edict_count)
		failed += 1
	if border_count < 4:
		printerr("路上应有划了又划的国境，实际 %d" % border_count)
		failed += 1
	if rat_trace_count < 2:
		printerr("背面应有老鼠痕迹，实际 %d" % rat_trace_count)
		failed += 1
	if not is_equal_approx(planet.radius, WorldConstants.KING_PLANET_RADIUS):
		printerr(
				"国王星球半径应为 %s，实际 %s"
				% [WorldConstants.KING_PLANET_RADIUS, planet.radius]
		)
		failed += 1
	if planet.star_rotation_speed != 0.0:
		printerr("国王星球天光应跟经度走，不应再靠星空自转追日落")
		failed += 1
	if not planet.spawn_on_opposite_side:
		printerr("国王星球应背面降落")
		failed += 1
	if not is_equal_approx(planet.audience_keep_away_arc, WorldConstants.KING_AUDIENCE_KEEP_AWAY_ARC):
		printerr("觐见禁区半宽应为常量")
		failed += 1
	if king != null:
		if not king.is_interactable() or king.get_dialogue_id() != &"king":
			printerr("国王应为可交互")
			failed += 1
		failed += _assert_focus(planet, king, &"king", "国王")
		planet.teleport_player(planet.spawn_angle)
		if planet.is_king_visible_from_player():
			printerr("开场王座不应在眼前")
			failed += 1
		if absf(angle_difference(planet.spawn_angle, planet.king_angle)) < 2.4:
			printerr("出生点应在国王对面")
			failed += 1
		var spawn_phase := SkyPhase.angle_to_phase(planet.sky.rotation)
		if spawn_phase > 0.12 and spawn_phase < 0.88:
			printerr("背面降落应为夜里，phase=%s" % spawn_phase)
			failed += 1
		planet.teleport_player(planet.king_angle)
		var throne_phase := SkyPhase.angle_to_phase(planet.sky.rotation)
		if absf(throne_phase - SkyPhase.NOON_PHASE) > 0.08:
			printerr("王座一侧应为白天，phase=%s" % throne_phase)
			failed += 1
		planet.teleport_player(planet.spawn_angle)
		failed += _assert_king_keep_away_and_facing(planet, king)
		failed += _assert_king_romantic_palette(planet, throne, cape)
	if rat != null:
		if rat.is_interactable() or story.accepts_interact(rat):
			printerr("耗子只作为装饰，不应可交互")
			failed += 1
		planet.teleport_player(rat.rotation)
		if planet.find_nearest_interactable() == rat:
			printerr("站在耗子旁不应选中耗子")
			failed += 1
	if rat_hole != null:
		if not rat_hole.is_interactable():
			printerr("耗子洞应可探")
			failed += 1
		planet.teleport_player(rat_hole.rotation)
		if planet.find_nearest_interactable() != rat_hole:
			printerr("站在洞口应选中洞，不应选中耗子")
			failed += 1

	if DialogueCatalog.lines_for_id(&"king").size() < 2:
		printerr("king 对话至少两句")
		failed += 1

	var king_tex := _scene_sprite_texture("res://planet/king.tscn", "Surface/King")
	if king_tex != null:
		var king_image := _texture_image(king_tex)
		var found_gold := false
		var found_robe := false
		for pixel_y in king_image.get_height():
			for pixel_x in king_image.get_width():
				var pixel := king_image.get_pixel(pixel_x, pixel_y)
				if pixel.a < 0.5:
					continue
				if pixel.r > 0.8 and pixel.g > 0.6 and pixel.b < 0.4:
					found_gold = true
				if pixel.r > pixel.g + 0.1 and pixel.r > pixel.b and pixel.s > 0.25:
					found_robe = true
		if not found_gold:
			printerr("国王贴图应含金色王冠")
			failed += 1
		if not found_robe:
			printerr("国王贴图应含红色袍服")
			failed += 1

	var king_portrait := load("res://ui/portraits/king.png") as Texture2D
	if king_portrait != null:
		var portrait_image := king_portrait.get_image()
		var border := portrait_image.get_pixel(0, 0)
		var expected_border := Color(255.0 / 255.0, 247.0 / 255.0, 209.0 / 255.0)
		if (
				absf(border.r - expected_border.r) > 0.02
				or absf(border.g - expected_border.g) > 0.02
				or absf(border.b - expected_border.b) > 0.02
		):
			printerr("国王头像边框应为奶油色，实际 %s" % border)
			failed += 1

	var dialogue := story.dialogue
	dialogue.play_line(
			DialogueLine.new(
					DialogueCatalog.KING_SPEAKER, "开口", DialogueCatalog.KING_PORTRAIT
			)
	)
	failed += _assert_dialogue_portrait_side(
			dialogue, "res://ui/portraits/king.png", false, "国王开口"
	)
	dialogue.close()

	if king == null:
		scene.queue_free()
		await process_frame
		return failed + 1

	planet.teleport_player(planet.spawn_angle)
	story.skip_cinematics = true
	await story.start()
	if not story.has_finished_opening:
		printerr("国王开场结束后应能走动")
		failed += 1
	if story.is_blocking_input:
		printerr("国王开场结束后应允许走动")
		failed += 1
	if not player.can_move_left or not player.can_move_right:
		printerr("国王开场后应能左右移动")
		failed += 1
	if story.accepts_interact(king):
		printerr("路上不应弹出见面对话")
		failed += 1
	var overhear_deadline_msec := Time.get_ticks_msec() + 1000
	while (
			not story.has_overheard_distant_sentencing
			and Time.get_ticks_msec() < overhear_deadline_msec
	):
		await process_frame
	if not story.has_overheard_distant_sentencing:
		printerr("靠近耗子洞应听见远处判刑又赦免")
		failed += 1
	if edict != null:
		planet.teleport_player(edict.rotation)
		if not story.accepts_interact(edict):
			printerr("路上诏书应可点一下")
			failed += 1
		if not story.try_handle_interact(edict):
			printerr("点诏书应读一句空令")
			failed += 1
	if border_line != null:
		planet.teleport_player(border_line.rotation)
		var border_offset_before := border_line.offset
		if not story.try_handle_interact(border_line):
			printerr("国境线应可踩一下")
			failed += 1
		await process_frame
		if border_line.offset.is_equal_approx(border_offset_before):
			printerr("踩国境线后线应抖一下")
			failed += 1
	if rat_hole != null:
		planet.teleport_player(rat_hole.rotation)
		if planet.find_nearest_interactable(story.accepts_interact) != rat_hole:
			printerr("路上应能对准耗子洞")
			failed += 1
		if not story.try_handle_interact(rat_hole):
			printerr("探洞应吱一声")
			failed += 1
		if not (rat_hole.get_node("Squeak") as AudioStreamPlayer).playing:
			printerr("探洞后应正在播放吱声")
			failed += 1
	if throne != null:
		planet.teleport_player(
				fposmod(planet.king_angle - planet.audience_keep_away_arc, TAU)
		)
		if planet.find_nearest_interactable(story.accepts_interact) != throne:
			printerr("禁区外应从左侧仰望空王座")
			failed += 1
		if not story.try_handle_interact(throne):
			printerr("禁区外点王座应只能仰一下")
			failed += 1
	if cape != null:
		planet.teleport_player(
				fposmod(planet.king_angle + planet.audience_keep_away_arc, TAU)
		)
		if planet.find_nearest_interactable(story.accepts_interact) != cape:
			printerr("禁区外应从右侧掀到披风边")
			failed += 1
		var cape_offset_before := cape.offset
		if not story.try_handle_interact(cape):
			printerr("披风边应可掀一点")
			failed += 1
		await process_frame
		if cape.offset.is_equal_approx(cape_offset_before):
			printerr("掀披风后应抬起一点")
			failed += 1
	planet.teleport_player(
			fposmod(
					planet.king_angle + WorldConstants.KING_DISTANT_VOICE_ARC - 0.02,
					TAU
			)
	)
	if not planet.is_in_distant_king_voice_range():
		printerr("靠近但未见国王时应进入先闻其声的范围")
		failed += 1
	if planet.is_king_visible_from_player():
		printerr("先闻其声时应还看不见人")
		failed += 1
	_drive_into_king_audience(planet)
	var meeting_deadline_msec := Time.get_ticks_msec() + 2000
	while (
			not planet.has_contacted_audience_keep_away
			and Time.get_ticks_msec() < meeting_deadline_msec
	):
		await process_frame
	if not planet.has_contacted_audience_keep_away:
		printerr("走到禁区应触发觐见")
		failed += 1
	var audience_player_angle := planet.player_angle
	var meeting_done_deadline_msec := Time.get_ticks_msec() + 2000
	while (
			not story.accepts_interact(king)
			and Time.get_ticks_msec() < meeting_done_deadline_msec
	):
		await process_frame
	if FileAccess.get_file_as_string("res://story/king_story.gd").contains("_meet_sunset"):
		printerr("国王章不应再走 _meet_sunset 追日落")
		failed += 1
	var king_source := FileAccess.get_file_as_string("res://story/king_story.gd")
	if (
			king_source.contains("太阳落山")
			or king_source.contains("我想看日落")
			or king_source.contains("_play_standing_sunset")
	):
		printerr("国王章不应再声称能控制或召唤日落")
		failed += 1
	if story.is_processing():
		printerr("国王章不应再按经度侦测日落")
		failed += 1
	if not is_equal_approx(planet.player_angle, audience_player_angle):
		printerr("觐见不应改变经度/走动，player_angle %s -> %s" % [audience_player_angle, planet.player_angle])
		failed += 1
	if absf(absf(planet.signed_angle_from_king()) - planet.audience_keep_away_arc) > 0.04:
		printerr("觐见后应仍在禁区外，偏移 %s" % planet.signed_angle_from_king())
		failed += 1
	if not is_nan(planet.sky.commanded_daylight_phase):
		printerr(
				"国王章天空相位应跟经度走，不应命令日落，phase=%s"
				% planet.sky.commanded_daylight_phase
		)
		failed += 1
	var music_before_king_meeting := scene.get_node("%Music").playing_stream as AudioStream
	failed += _assert_playing_stream(scene, music_before_king_meeting, "国王觐见不应切换配乐")
	if story.is_blocking_input:
		printerr("国王见面对话后应恢复输入")
		failed += 1
	if not story.accepts_interact(king):
		printerr("见面高潮后应能继续司法大臣对话")
		failed += 1
	if not story.try_handle_interact(king):
		printerr("见面高潮后应按 A 继续司法大臣对话")
		failed += 1
	if not king.is_consumed:
		printerr("告别后国王应消耗")
		failed += 1
	if player.modulate.a > 0.01:
		printerr("离星后小王子应消失")
		failed += 1
	if story.get_node("%Dim").color.a < 0.99:
		printerr("离星后应淡出到黑场")
		failed += 1
	if story.get_node("%Epilogue").text != "325。":
		printerr("黑场应留下 325。，实际 %s" % story.get_node("%Epilogue").text)
		failed += 1

	if failed == 0:
		print("  国王星球演出 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_standalone_planet_scenes() -> int:
	var failed := 0
	failed += await _assert_standalone_planet_run(
			"res://planet/b612.tscn",
			B612Story,
			"res://audio/the_one_who_stands_distant.ogg",
			"B612 单独运行"
	)
	failed += await _assert_standalone_planet_run(
			"res://planet/king.tscn",
			KingStory,
			"res://audio/narrow_cpenta_toy_waltz.ogg",
			"国王星球单独运行"
	)
	failed += await _assert_standalone_planet_run(
			"res://planet/vain.tscn",
			PlanetStory,
			"res://audio/the_one_who_stands_distant.ogg",
			"虚荣者星球单独运行"
	)
	failed += await _assert_standalone_planet_run(
			"res://planet/drunkard.tscn",
			DrunkardStory,
			"res://audio/i_want_to_go_home.ogg",
			"酒鬼星球单独运行"
	)
	failed += await _assert_standalone_planet_run(
			"res://planet/merchant.tscn",
			MerchantStory,
			"res://audio/sparse_ledger_tally.ogg",
			"商人星球单独运行"
	)
	failed += await _assert_standalone_planet_run(
			"res://planet/lamplighter.tscn",
			LamplighterStory,
			"res://audio/rapid_lamp_duty_tick.ogg",
			"点灯人星球单独运行"
	)
	failed += await _assert_standalone_planet_run(
			"res://planet/geographer.tscn",
			GeographerStory,
			"res://audio/dry_folio_rest.ogg",
			"地理学家星球单独运行"
	)
	var base_planet := (load("res://planet/planet.tscn") as PackedScene).instantiate() as Planet
	root.add_child(base_planet)
	await process_frame
	await process_frame
	if base_planet.get_parent() != root:
		printerr("planet.tscn 基底不应套运行壳")
		failed += 1
		var wrapped_shell := base_planet.get_parent().get_parent().get_parent()
		wrapped_shell.queue_free()
	else:
		base_planet.queue_free()
	await process_frame
	if failed == 0:
		print("  星球 tscn 单独运行壳 OK")
	return failed


func _assert_standalone_planet_run(
		planet_path: String,
		expected_story_type: GDScript,
		expected_music_path: String,
		label: String,
) -> int:
	var failed := 0
	var planet := (load(planet_path) as PackedScene).instantiate() as Planet
	root.add_child(planet)
	await process_frame
	await process_frame
	if not planet.is_inside_tree() or planet.get_parent() == root:
		printerr("%s 应套上运行壳" % label)
		if planet.is_inside_tree():
			planet.queue_free()
			await process_frame
		return 1
	var shell := planet.get_parent().get_parent().get_parent() as PlanetRunShell
	if shell == null:
		printerr("%s 运行壳应为 PlanetRunShell" % label)
		planet.get_parent().get_parent().get_parent().queue_free()
		await process_frame
		return 1
	if planet.scene_file_path != planet_path:
		printerr("%s 星球应为 %s，实际 %s" % [label, planet_path, planet.scene_file_path])
		failed += 1
	var player := shell.get_node_or_null(PLAYER_PATH) as Player
	if player == null:
		printerr("%s 应看见玩家" % label)
		failed += 1
	elif player.planet != planet:
		printerr("%s 玩家应绑定该星" % label)
		failed += 1
	var story := shell.get_node("%Story")
	if story.get_script() != expected_story_type:
		printerr("%s 故事脚本应为 %s" % [label, expected_story_type.resource_path])
		failed += 1
	if planet_path == "res://planet/king.tscn":
		var has_king := false
		var has_rose := false
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.KING:
				has_king = true
			if prop.kind == SurfaceProp.Kind.ROSE:
				has_rose = true
		if not has_king:
			printerr("国王单独运行应有国王")
			failed += 1
		if has_rose:
			printerr("国王单独运行不应有玫瑰")
			failed += 1
	if planet_path == "res://planet/vain.tscn":
		if player != null and (not player.can_move_left or not player.can_move_right):
			printerr("虚荣者星球应能走动")
			failed += 1
		if (story as B612Story) != null or (story as KingStory) != null:
			printerr("虚荣者星球不应挂 B612/国王演出")
			failed += 1
	if planet_path == "res://planet/drunkard.tscn":
		var bottle_count := 0
		var has_drunkard := false
		var has_king := false
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.BOTTLE:
				bottle_count += 1
			if prop.kind == SurfaceProp.Kind.DRUNKARD:
				has_drunkard = true
			if prop.kind == SurfaceProp.Kind.KING:
				has_king = true
		if not has_drunkard:
			printerr("酒鬼单独运行应有酒鬼")
			failed += 1
		if has_king:
			printerr("酒鬼单独运行不应有国王")
			failed += 1
		if bottle_count != WorldConstants.DRUNKARD_BOTTLE_COUNT:
			printerr(
					"酒鬼单独运行瓶子应为 %d，实际 %d"
					% [WorldConstants.DRUNKARD_BOTTLE_COUNT, bottle_count]
			)
			failed += 1
	if planet_path == "res://planet/merchant.tscn":
		var merchant_count := 0
		var jar_count := 0
		var has_foreign_chapter := false
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.MERCHANT:
				merchant_count += 1
			if prop.kind == SurfaceProp.Kind.STAR_JAR:
				jar_count += 1
			if prop.kind in [
					SurfaceProp.Kind.KING,
					SurfaceProp.Kind.ROSE,
					SurfaceProp.Kind.DRUNKARD,
					SurfaceProp.Kind.BOTTLE,
			]:
				has_foreign_chapter = true
		if merchant_count != 1:
			printerr("商人单独运行应有一名商人")
			failed += 1
		if jar_count != 1:
			printerr("商人单独运行应只有一只玻璃罐")
			failed += 1
		if has_foreign_chapter:
			printerr("商人单独运行不应有其它章地物")
			failed += 1
	if planet_path == "res://planet/lamplighter.tscn":
		var lamplighter_count := 0
		var lamp_count := 0
		var has_foreign_chapter := false
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.LAMPLIGHTER:
				lamplighter_count += 1
			if prop.kind == SurfaceProp.Kind.STREET_LAMP:
				lamp_count += 1
			if prop.kind in [
					SurfaceProp.Kind.KING,
					SurfaceProp.Kind.ROSE,
					SurfaceProp.Kind.DRUNKARD,
					SurfaceProp.Kind.BOTTLE,
					SurfaceProp.Kind.MERCHANT,
					SurfaceProp.Kind.STAR_JAR,
					SurfaceProp.Kind.GEOGRAPHER,
					SurfaceProp.Kind.INK_REPORT,
			]:
				has_foreign_chapter = true
		if lamplighter_count != 1:
			printerr("点灯人单独运行应有一名点灯人")
			failed += 1
		if lamp_count != 1:
			printerr("点灯人单独运行应只有一盏灯")
			failed += 1
		if has_foreign_chapter:
			printerr("点灯人单独运行不应有其它章地物")
			failed += 1
		if not is_equal_approx(planet.radius, WorldConstants.LAMPLIGHTER_PLANET_RADIUS):
			printerr("点灯人单独运行半径应是最小那颗")
			failed += 1
		if not is_equal_approx(
				planet.sky.star_rotation_speed,
				WorldConstants.LAMPLIGHTER_STAR_ROTATION_SPEED
		):
			printerr("点灯人单独运行星空应极快自转")
			failed += 1
	if planet_path == "res://planet/geographer.tscn":
		var geographer_count := 0
		var report_count := 0
		var has_foreign_chapter := false
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.GEOGRAPHER:
				geographer_count += 1
			if prop.kind == SurfaceProp.Kind.INK_REPORT:
				report_count += 1
			if prop.kind in [
					SurfaceProp.Kind.KING,
					SurfaceProp.Kind.ROSE,
					SurfaceProp.Kind.DRUNKARD,
					SurfaceProp.Kind.BOTTLE,
					SurfaceProp.Kind.MERCHANT,
					SurfaceProp.Kind.STAR_JAR,
					SurfaceProp.Kind.LAMPLIGHTER,
					SurfaceProp.Kind.STREET_LAMP,
					SurfaceProp.Kind.VOLCANO,
					SurfaceProp.Kind.BAOBAB,
					SurfaceProp.Kind.FLORA,
			]:
				has_foreign_chapter = true
		if geographer_count != 1:
			printerr("地理学家单独运行应有一名地理学家")
			failed += 1
		if report_count != WorldConstants.GEOGRAPHER_REPORT_STACK_COUNT:
			printerr(
					"地理学家单独运行报告堆应为 %d，实际 %d"
					% [WorldConstants.GEOGRAPHER_REPORT_STACK_COUNT, report_count]
			)
			failed += 1
		if has_foreign_chapter:
			printerr("地理学家单独运行不应有风景或其它章地物")
			failed += 1
		if FileAccess.file_exists("res://planet/earth.tscn"):
			printerr("地球关卡这轮仍不应存在")
			failed += 1
	failed += _assert_playing_stream(
			shell,
			load(expected_music_path) as AudioStream,
			"%s应播放配乐" % label
	)
	shell.queue_free()
	await process_frame
	return failed


func _check_b612_depart_lift_halfway_overhead() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	scene.travel_to_next_planet = false
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("%Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame

	var story := scene.get_node("%Story") as B612Story
	var player := scene.get_node(PLAYER_PATH) as Player
	var overhead := story.overhead
	var overhead_body := overhead.get_node("Body") as Label
	var dim := story.get_node("%Dim") as ColorRect
	const first_overhead := "玫瑰不想小王子看见她在哭"
	const second_overhead := "她总是这么傲娇"
	story.skip_cinematics = false
	player.modulate.a = 1.0
	dim.color.a = 0.0
	var start_player_y := player.position.y
	var depart_started_msec := Time.get_ticks_msec()
	story._depart(
			"B-612。",
			PackedStringArray([first_overhead, second_overhead])
	)

	var too_early_deadline_msec := depart_started_msec + int(
			(
				MigratoryFlock.ARRIVE_SECONDS
				+ PlanetStory.LIFT_DURATION_SECONDS * 0.5
			) * 1000.0
	)
	while Time.get_ticks_msec() < too_early_deadline_msec:
		if overhead.visible and overhead_body.text == first_overhead:
			printerr("离星旁白过早，小王子还未飞到一半")
			failed += 1
			break
		if player.modulate.a < 0.99:
			printerr("飞到一半前小王子不应开始消失")
			failed += 1
			break
		if dim.color.a > 0.05:
			printerr("旁白播完前不应黑屏")
			failed += 1
			break
		await process_frame

	var first_deadline_msec := depart_started_msec + int(
			(
				MigratoryFlock.ARRIVE_SECONDS
				+ PlanetStory.LIFT_DURATION_SECONDS * 0.5
				+ PlanetStory.LIFT_HALFWAY_OVERHEAD_EXTRA_SECONDS
				+ 1.0
			) * 1000.0
	)
	var first_started_msec := -1
	while Time.get_ticks_msec() < first_deadline_msec:
		if overhead.visible and overhead_body.text == first_overhead:
			first_started_msec = Time.get_ticks_msec()
			break
		await process_frame
	if first_started_msec < 0:
		printerr("飞到一半后应播放玫瑰旁白")
		scene.queue_free()
		await process_frame
		return failed + 1

	var first_delay_msec := first_started_msec - depart_started_msec
	var expected_delay_msec := int(
			(
				MigratoryFlock.ARRIVE_SECONDS
				+ PlanetStory.LIFT_DURATION_SECONDS * 0.5
				+ PlanetStory.LIFT_HALFWAY_OVERHEAD_EXTRA_SECONDS
			) * 1000.0
	)
	if first_delay_msec < expected_delay_msec - 400:
		printerr("玫瑰旁白过早，飞起仅 %d ms" % first_delay_msec)
		failed += 1
	if first_delay_msec > expected_delay_msec + 600:
		printerr("玫瑰旁白过晚，飞起已 %d ms" % first_delay_msec)
		failed += 1
	if player.modulate.a < 0.99:
		printerr("旁白开始时小王子还不应消失，alpha=%s" % player.modulate.a)
		failed += 1
	if dim.color.a > 0.05:
		printerr("旁白开始时不应黑屏，alpha=%s" % dim.color.a)
		failed += 1
	var lifted_pixels := start_player_y - player.position.y
	if lifted_pixels < (start_player_y + float(WorldConstants.PLAYER_SPRITE_HEIGHT)) * 0.5:
		printerr(
				"旁白开始时小王子应已飞过半程，实际 %s"
				% lifted_pixels
		)
		failed += 1
	var remaining_lift_seconds := (
			MigratoryFlock.ARRIVE_SECONDS
			+ PlanetStory.LIFT_DURATION_SECONDS
			- float(first_delay_msec) / 1000.0
	)
	if remaining_lift_seconds > 0.0:
		await create_timer(remaining_lift_seconds + 0.15).timeout
	var viewport_rect := (
			scene.get_node(VIEWPORT_PATH) as SubViewport
	).get_visible_rect()
	if (
			player.global_position.y + float(WorldConstants.PLAYER_SPRITE_HEIGHT)
			> viewport_rect.position.y
	):
		printerr("小王子应已飞出屏幕上沿，y=%s" % player.global_position.y)
		failed += 1

	var second_deadline_msec := first_started_msec + 8000
	var second_started_msec := -1
	while Time.get_ticks_msec() < second_deadline_msec:
		if dim.color.a > 0.05:
			printerr("两句旁白播完前不应黑屏")
			failed += 1
			break
		if overhead.visible and overhead_body.text == second_overhead:
			second_started_msec = Time.get_ticks_msec()
			break
		await process_frame
	if second_started_msec < 0:
		printerr("第一句之后应播放「她总是这么傲娇」")
		failed += 1
	elif dim.color.a > 0.05:
		printerr("第二句开始时不应黑屏，alpha=%s" % dim.color.a)
		failed += 1

	var black_deadline_msec := Time.get_ticks_msec() + 12000
	while dim.color.a < 0.99 and Time.get_ticks_msec() < black_deadline_msec:
		if overhead.visible:
			if dim.color.a > 0.05:
				printerr("旁白尚未播完就黑屏")
				failed += 1
				break
		await process_frame
	if dim.color.a < 0.99:
		printerr("旁白播完后应黑屏")
		failed += 1
	var epilogue_deadline_msec := Time.get_ticks_msec() + 1000
	while (
			story.get_node("%Epilogue").text != "B-612。"
			and Time.get_ticks_msec() < epilogue_deadline_msec
	):
		await process_frame
	if story.get_node("%Epilogue").text != "B-612。":
		printerr(
				"黑场应留下 B-612。，实际 %s"
				% story.get_node("%Epilogue").text
		)
		failed += 1
	await create_timer(PlanetStory.EPILOGUE_HOLD_SECONDS + 0.3).timeout
	if failed == 0:
		print("  B612 离星飞到一半旁白 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_b612_departed_travels_to_king() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("%Story") as B612Story).auto_start = false
	(scene.get_node("%KingStory") as KingStory).skip_cinematics = true
	root.add_child(scene)
	await process_frame
	await process_frame
	(scene.get_node("%Story") as B612Story).departed.emit()
	await process_frame
	await process_frame
	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var king_story := scene.get_node("%KingStory") as KingStory
	if planet == null or planet.scene_file_path != "res://planet/king.tscn":
		printerr(
				"B612 离星后应换到国王星球，实际 %s"
				% (planet.scene_file_path if planet != null else "null")
		)
		failed += 1
	if king_story.planet != planet:
		printerr("离星换星后 KingStory 应绑定国王星球")
		failed += 1
	failed += _assert_playing_music(scene, "king_day_music", "离星换星")
	var opening_deadline_msec := Time.get_ticks_msec() + 5000
	while (
			not king_story.has_finished_opening
			and Time.get_ticks_msec() < opening_deadline_msec
	):
		await process_frame
	if not king_story.has_finished_opening:
		printerr("换星后国王开场应自动开始")
		failed += 1
	if failed == 0:
		print("  B612 离星后进入国王星球 OK")
	scene.queue_free()
	await process_frame
	return failed


func _await_physics_queries() -> void:
	for _frame_index in 6:
		await physics_frame


func _check_footsteps() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	scene.travel_to_next_planet = false
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame

	var planet: Planet = scene.get_node(PLANET_PATH) as Planet
	var player: Player = scene.get_node(PLAYER_PATH) as Player
	var footprint := scene.get_node("%Footprint") as Area2D
	var footstep := scene.get_node("%Footstep")
	var story := scene.get_node("%Story") as PlanetStory
	if footprint == null or footstep == null:
		printerr("Player 下应有 Footprint 与 Footstep")
		scene.queue_free()
		await process_frame
		return 1

	failed += _assert_walking_footstep_playback(planet, player, footstep, story)
	failed += await _assert_flora_grass_areas(planet, player, footprint)
	failed += await _assert_dirt_grass_footstep_switch(planet, player, footstep)

	if failed == 0:
		print("  行走脚步通路 / FLORA 草丛 Area / 土草切换 OK")
	scene.queue_free()
	await process_frame
	return failed


func _plant_walk_step(player: Player, planet: Planet, move_direction: float) -> void:
	planet.angular_velocity = 0.4 if move_direction >= 0.0 else -0.4
	player._was_moving = false
	player._last_walk_frame_index = -1
	player._anim_time = 0.0
	player._update_animation(move_direction, 0.0)


func _halt_walk(player: Player, planet: Planet) -> void:
	planet.angular_velocity = 0.0
	player._was_moving = true
	player._update_animation(0.0, 0.0)


func _assert_walking_footstep_playback(
		planet: Planet, player: Player, footstep: Node, story: PlanetStory
) -> int:
	var failed := 0
	var footstep_player := footstep as AudioStreamPlayer
	if footstep_player.volume_db > linear_to_db(0.12):
		printerr("脚步应明显轻于上一档，volume_db=%s" % footstep_player.volume_db)
		failed += 1
	if footstep_player.volume_db < linear_to_db(0.06):
		printerr("脚步过轻，volume_db=%s" % footstep_player.volume_db)
		failed += 1
	planet.teleport_player(planet.rose_angle)
	_plant_walk_step(player, planet, 1.0)
	if footstep.played_step_count != 1:
		printerr("向右走落地应播放脚步，实际 %d" % footstep.played_step_count)
		failed += 1
	planet.angular_velocity = 0.0
	player._update_animation(0.0, 0.05)
	if footstep.playing:
		printerr("停下应立刻停止脚步")
		failed += 1
	var count_after_stop: int = footstep.played_step_count
	player._update_animation(0.0, 0.5)
	if footstep.played_step_count != count_after_stop:
		printerr("静止不应继续响脚步")
		failed += 1
	player.flip_h = false
	_plant_walk_step(player, planet, -1.0)
	if not player.flip_h:
		printerr("向左走时 flip_h 应为 true")
		failed += 1
	if footstep.played_step_count != count_after_stop + 1:
		printerr("向左走落地也应播放脚步")
		failed += 1
	story.is_blocking_input = true
	var count_before_lock: int = footstep.played_step_count
	_plant_walk_step(player, planet, 1.0)
	if footstep.played_step_count != count_before_lock:
		printerr("对话锁输入时不应响脚步")
		failed += 1
	story.is_blocking_input = false
	_halt_walk(player, planet)
	if failed == 0:
		print("  行走脚步通路 OK")
	return failed


func _assert_flora_grass_areas(planet: Planet, player: Player, footprint: Area2D) -> int:
	var failed := 0
	if footprint.collision_layer != 0:
		printerr("脚底 Area 不应占据实心碰撞层")
		failed += 1
	if not footprint.get_collision_mask_value(WorldConstants.FLORA_GRASS_PHYSICS_LAYER_INDEX):
		printerr("脚底 Area 应只检测草丛触发层")
		failed += 1
	if footprint.monitorable or footprint.input_pickable:
		printerr("脚底 Area 不应挡互动或被其它 Area 当成障碍")
		failed += 1
	var footprint_shape := footprint.get_child(0) as CollisionShape2D
	var footprint_circle := footprint_shape.shape as CircleShape2D
	if not is_equal_approx(footprint_circle.radius, WorldConstants.PLAYER_FOOTPRINT_RADIUS):
		printerr(
				"脚底圆半径应为 %s，实际 %s"
				% [WorldConstants.PLAYER_FOOTPRINT_RADIUS, footprint_circle.radius]
		)
		failed += 1

	var flora_props: Array[SurfaceProp] = []
	for prop in planet.surface_props:
		if prop.kind == SurfaceProp.Kind.FLORA:
			flora_props.append(prop)
			var trigger := prop.get_node_or_null("GrassClumpTrigger") as Area2D
			if trigger == null:
				printerr("FLORA %s 应挂一份草丛 Area" % prop.name)
				failed += 1
				continue
			if trigger.get_child_count() != 1:
				printerr("FLORA %s 应为每丛一份 Area，不要按每根草切" % prop.name)
				failed += 1
			if trigger.monitoring or trigger.input_pickable:
				printerr("草丛 Area 不应扫描或拦截输入：%s" % prop.name)
				failed += 1
			if trigger.collision_mask != 0:
				printerr("草丛 Area 不应检测其它层：%s" % prop.name)
				failed += 1
			if not trigger.get_collision_layer_value(WorldConstants.FLORA_GRASS_PHYSICS_LAYER_INDEX):
				printerr("草丛 Area 应挂在草丛触发层：%s" % prop.name)
				failed += 1
			var trigger_shape := trigger.get_child(0) as CollisionShape2D
			var trigger_circle := trigger_shape.shape as CircleShape2D
			if trigger_circle.radius <= WorldConstants.FLORA_SPRITE_SIZE * 0.5:
				printerr("草丛 Area 应比视觉稍大：%s" % prop.name)
				failed += 1
			if not is_equal_approx(trigger_circle.radius, WorldConstants.FLORA_GRASS_TRIGGER_RADIUS):
				printerr(
						"草丛 Area 半径应为 %s，实际 %s（%s）"
						% [WorldConstants.FLORA_GRASS_TRIGGER_RADIUS, trigger_circle.radius, prop.name]
				)
				failed += 1
		elif prop.get_node_or_null("GrassClumpTrigger") != null:
			printerr("非 FLORA 地物不应挂草丛 Area：%s" % prop.name)
			failed += 1

	planet.teleport_player(planet.rose_angle)
	await _await_physics_queries()
	if player.is_in_grass():
		printerr("玫瑰旁默认不应判定在草丛")
		failed += 1
	if flora_props.is_empty():
		printerr("应有 FLORA 用于草丛 Area 验证")
		return failed + 1

	planet.teleport_player(flora_props[0].rotation)
	await _await_physics_queries()
	if not player.is_in_grass():
		printerr("走进 FLORA Area 应判定在草丛")
		failed += 1
	planet.teleport_player(planet.rose_angle)
	await _await_physics_queries()
	if player.is_in_grass():
		printerr("离开草丛后应恢复不在草丛")
		failed += 1

	var clump_a: SurfaceProp = flora_props[0]
	var clump_b: SurfaceProp = flora_props[0]
	var closest_arc := INF
	for first_index in flora_props.size():
		for second_index in range(first_index + 1, flora_props.size()):
			var arc_px := (
					absf(angle_difference(
							flora_props[first_index].rotation,
							flora_props[second_index].rotation
					))
					* planet.radius
			)
			if arc_px < closest_arc:
				closest_arc = arc_px
				clump_a = flora_props[first_index]
				clump_b = flora_props[second_index]
	var overlap_span := (
			WorldConstants.FLORA_GRASS_TRIGGER_RADIUS * 2.0
			+ WorldConstants.PLAYER_FOOTPRINT_RADIUS
	)
	if closest_arc > overlap_span:
		printerr("找不到可重叠的草丛 Area 对，最近弧长 %s" % closest_arc)
		failed += 1
	else:
		var overlap_flickered := false
		for sample_index in 5:
			var sample_weight := float(sample_index) / 4.0
			planet.teleport_player(
					lerp_angle(clump_a.rotation, clump_b.rotation, sample_weight)
			)
			await _await_physics_queries()
			if not player.is_in_grass():
				overlap_flickered = true
		if overlap_flickered:
			printerr("重叠多个草丛 Area 时应保持在草丛，不要抖切")
			failed += 1
	if failed == 0:
		print("  FLORA 草丛 Area OK")
	return failed


func _assert_dirt_grass_footstep_switch(
		planet: Planet, player: Player, footstep: Node
) -> int:
	var failed := 0
	var flora_prop: SurfaceProp = null
	for prop in planet.surface_props:
		if prop.kind == SurfaceProp.Kind.FLORA:
			flora_prop = prop
			break
	if flora_prop == null:
		printerr("土/草切换需要已存在的 FLORA Area 通路")
		return 1

	planet.teleport_player(planet.rose_angle)
	await _await_physics_queries()
	_plant_walk_step(player, planet, 1.0)
	if footstep.last_step_was_grass:
		printerr("不在草丛时应为土地脚步")
		failed += 1
	_halt_walk(player, planet)

	planet.teleport_player(flora_prop.rotation)
	await _await_physics_queries()
	if not player.is_in_grass():
		printerr("土/草切换前应先能判定在草丛 Area 内")
		failed += 1
	_plant_walk_step(player, planet, 1.0)
	if not footstep.last_step_was_grass:
		printerr("草丛内应为草地脚步")
		failed += 1
	_halt_walk(player, planet)

	planet.teleport_player(planet.rose_angle)
	await _await_physics_queries()
	_plant_walk_step(player, planet, 1.0)
	if footstep.last_step_was_grass:
		printerr("离开草丛后应切回土地脚步")
		failed += 1
	_halt_walk(player, planet)
	if failed == 0:
		print("  土/草脚步切换 OK")
	return failed


func _check_drunkard_chapter() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_king_planet(false)
	await process_frame
	scene.travel_to_drunkard_planet(false)
	await process_frame

	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var player: Player = scene.get_node_or_null(PLAYER_PATH) as Player
	var story := scene.get_node_or_null("%DrunkardStory") as DrunkardStory
	if planet == null or player == null or story == null:
		printerr("酒鬼章缺少 Planet / Player / DrunkardStory")
		scene.queue_free()
		await process_frame
		return 1
	if planet.scene_file_path != "res://planet/drunkard.tscn":
		printerr("国王之后星球应为 drunkard.tscn，实际 %s" % planet.scene_file_path)
		failed += 1
	failed += _assert_playing_music(scene, "drunkard_day_music", "换到酒鬼星球")
	if story.planet != planet:
		printerr("换星后 DrunkardStory 应绑定酒鬼星球")
		failed += 1
	if (scene.get_node("%Interaction") as Interaction).story != story:
		printerr("换星后 Interaction 应绑定 DrunkardStory")
		failed += 1

	var drunkard: SurfaceProp = null
	var bottle_count := 0
	var bottle_angles: Array[float] = []
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.DRUNKARD:
				drunkard = prop
			SurfaceProp.Kind.BOTTLE:
				bottle_count += 1
				bottle_angles.append(prop.rotation)
				if prop.is_interactable() or story.accepts_interact(prop):
					printerr("瓶子不应可交互：%s" % prop.name)
					failed += 1
			SurfaceProp.Kind.KING, SurfaceProp.Kind.ROSE, SurfaceProp.Kind.VOLCANO, SurfaceProp.Kind.BAOBAB, SurfaceProp.Kind.FLORA:
				printerr("酒鬼星球不应有其它章地物 %s" % prop.name)
				failed += 1
	if drunkard == null:
		printerr("酒鬼星球应有酒鬼")
		failed += 1
	if bottle_count != WorldConstants.DRUNKARD_BOTTLE_COUNT:
		printerr(
				"酒鬼星球瓶子应为 %d，实际 %d"
				% [WorldConstants.DRUNKARD_BOTTLE_COUNT, bottle_count]
		)
		failed += 1
	bottle_angles.sort()
	var ring_angles: Array[float] = bottle_angles.duplicate()
	if drunkard != null:
		ring_angles.append(drunkard.rotation)
		ring_angles.sort()
	var widest_gap := 0.0
	for gap_index in ring_angles.size():
		var from_angle: float = ring_angles[gap_index]
		var to_angle: float = ring_angles[(gap_index + 1) % ring_angles.size()]
		var gap := fposmod(to_angle - from_angle, TAU)
		widest_gap = maxf(widest_gap, gap)
	if widest_gap > TAU / 8.0:
		printerr("瓶子圈空隙过大，实际 %s" % widest_gap)
		failed += 1
	if drunkard != null:
		failed += _assert_focus(planet, drunkard, &"drunkard", "酒鬼")
		planet.teleport_player(fposmod(drunkard.rotation + PI, TAU))
		var visible_bottles := 0
		for prop in planet.surface_props:
			if prop.kind == SurfaceProp.Kind.BOTTLE and prop.visible:
				visible_bottles += 1
		if visible_bottles < 3:
			printerr("走到对面仍应困在瓶子圈里，可见瓶子 %d" % visible_bottles)
			failed += 1

	var drunkard_lines := DialogueCatalog.lines_for_id(&"drunkard")
	if drunkard_lines.size() != 1 or drunkard_lines[0].text != "喝是为了忘羞耻":
		printerr("酒鬼台词应只有「喝是为了忘羞耻」")
		failed += 1

	var body_image := (planet.body.texture as Texture2D).get_image()
	var amber_pixels := 0
	var cool_pixels := 0
	var opaque_pixels := 0
	for pixel_y in range(0, body_image.get_height(), 4):
		for pixel_x in range(0, body_image.get_width(), 4):
			var pixel := body_image.get_pixel(pixel_x, pixel_y)
			if pixel.a < 0.5:
				continue
			opaque_pixels += 1
			if pixel.r > pixel.b + 0.12 and pixel.r > pixel.g - 0.02:
				amber_pixels += 1
			if pixel.b > pixel.r + 0.04 or pixel.g > pixel.r + 0.08:
				cool_pixels += 1
	if opaque_pixels == 0 or float(amber_pixels) / float(opaque_pixels) < 0.45:
		printerr("酒鬼星球地面应偏琥珀")
		failed += 1
	if float(cool_pixels) / float(opaque_pixels) > 0.2:
		printerr("酒鬼星球地面不应偏国王那颗的绿蓝")
		failed += 1
	var amber_zenith := (
			planet.sky.material as ShaderMaterial
	).get_shader_parameter("zenith_gradient") as GradientTexture1D
	if amber_zenith == null:
		printerr("酒鬼星球应有琥珀傍晚天空")
		failed += 1
	else:
		var sunset := amber_zenith.gradient.sample(SkyPhase.SUNSET_PHASE)
		var noon := amber_zenith.gradient.sample(SkyPhase.NOON_PHASE)
		if sunset.r <= sunset.b or sunset.r <= sunset.g:
			printerr("傍晚天空应偏琥珀，实际 %s" % sunset)
			failed += 1
		if noon.g > noon.r and noon.g > noon.b:
			printerr("酒鬼天空不应像国王正午绿天，实际 %s" % noon)
			failed += 1
		if noon.b > noon.r:
			printerr("酒鬼天空不应像白天蓝天，实际 %s" % noon)
			failed += 1

	if drunkard == null:
		scene.queue_free()
		await process_frame
		return failed + 1

	planet.teleport_player(planet.spawn_angle)
	story.skip_cinematics = true
	await story.start()
	if not is_equal_approx(planet.sky.commanded_daylight_phase, SkyPhase.SUNSET_PHASE):
		printerr("酒鬼星球天光应锁在傍晚")
		failed += 1
	if planet.sky.is_self_rotating:
		printerr("酒鬼星球天空不应再自转成白天")
		failed += 1
	if not story.has_finished_opening:
		printerr("酒鬼开场结束后应能走动")
		failed += 1
	if story.is_blocking_input:
		printerr("酒鬼开场结束后应允许走动")
		failed += 1
	if not player.can_move_left or not player.can_move_right:
		printerr("酒鬼开场后应能左右移动")
		failed += 1
	if not story.accepts_interact(drunkard):
		printerr("开场后应能与酒鬼交谈")
		failed += 1
	var dialogue := story.dialogue
	dialogue.play_line(
			DialogueLine.new(
					DialogueCatalog.DRUNKARD_SPEAKER,
					"喝是为了忘羞耻",
					DialogueCatalog.DRUNKARD_PORTRAIT
			)
	)
	failed += _assert_dialogue_portrait_side(
			dialogue, "res://ui/portraits/slumped_wine_drinker.png", false, "酒鬼开口"
	)
	dialogue.close()
	if not story.try_handle_interact(drunkard):
		printerr("开场后应按 A 听酒鬼那一句")
		failed += 1
	if not drunkard.is_consumed:
		printerr("听完后酒鬼应消耗")
		failed += 1
	if player.modulate.a > 0.01:
		printerr("离星后小王子应消失")
		failed += 1
	if story.get_node("%Epilogue").text != "327。":
		printerr("黑场应留下 327。，实际 %s" % story.get_node("%Epilogue").text)
		failed += 1
	if failed == 0:
		print("  酒鬼星球演出 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_king_departed_travels_to_drunkard() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("%Story") as B612Story).auto_start = false
	(scene.get_node("%KingStory") as KingStory).skip_cinematics = true
	(scene.get_node("%DrunkardStory") as DrunkardStory).skip_cinematics = true
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_king_planet(true)
	await process_frame
	await process_frame
	var king_story := scene.get_node("%KingStory") as KingStory
	king_story._story_generation += 1
	king_story.is_active = false
	king_story.set_process(false)
	king_story.departed.emit()
	await process_frame
	await process_frame
	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var drunkard_story := scene.get_node("%DrunkardStory") as DrunkardStory
	if planet == null or planet.scene_file_path != "res://planet/drunkard.tscn":
		printerr(
				"国王离星后应换到酒鬼星球，实际 %s"
				% (planet.scene_file_path if planet != null else "null")
		)
		failed += 1
	if drunkard_story.planet != planet:
		printerr("离星换星后 DrunkardStory 应绑定酒鬼星球")
		failed += 1
	failed += _assert_playing_music(scene, "drunkard_day_music", "国王离星换星")
	var opening_deadline_msec := Time.get_ticks_msec() + 5000
	while (
			not drunkard_story.has_finished_opening
			and Time.get_ticks_msec() < opening_deadline_msec
	):
		await process_frame
	if not drunkard_story.has_finished_opening:
		printerr("换星后酒鬼开场应自动开始")
		failed += 1
	if failed == 0:
		print("  国王离星后进入酒鬼星球 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_merchant_chapter() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_king_planet(false)
	await process_frame
	scene.travel_to_drunkard_planet(false)
	await process_frame
	scene.travel_to_merchant_planet(false)
	await process_frame

	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var player: Player = scene.get_node_or_null(PLAYER_PATH) as Player
	var story := scene.get_node_or_null("%MerchantStory") as MerchantStory
	if planet == null or player == null or story == null:
		printerr("商人章缺少 Planet / Player / MerchantStory")
		scene.queue_free()
		await process_frame
		return 1
	if planet.scene_file_path != "res://planet/merchant.tscn":
		printerr("酒鬼之后星球应为 merchant.tscn，实际 %s" % planet.scene_file_path)
		failed += 1
	failed += _assert_playing_music(scene, "merchant_day_music", "换到商人星球")
	if story.planet != planet:
		printerr("换星后 MerchantStory 应绑定商人星球")
		failed += 1
	if (scene.get_node("%Interaction") as Interaction).story != story:
		printerr("换星后 Interaction 应绑定 MerchantStory")
		failed += 1

	var merchant: SurfaceProp = null
	var star_jar: SurfaceProp = null
	var jar_count := 0
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.MERCHANT:
				merchant = prop
				if prop.is_interactable() or story.accepts_interact(prop):
					printerr("商人不应可交互")
					failed += 1
			SurfaceProp.Kind.STAR_JAR:
				star_jar = prop
				jar_count += 1
			SurfaceProp.Kind.KING, SurfaceProp.Kind.ROSE, SurfaceProp.Kind.DRUNKARD, SurfaceProp.Kind.BOTTLE, SurfaceProp.Kind.VOLCANO, SurfaceProp.Kind.BAOBAB, SurfaceProp.Kind.FLORA:
				printerr("商人星球不应有其它章地物 %s" % prop.name)
				failed += 1
	if merchant == null:
		printerr("商人星球应有商人")
		failed += 1
	if jar_count != 1 or star_jar == null:
		printerr("商人星球应只有一只玻璃罐")
		failed += 1

	var body_image := (planet.body.texture as Texture2D).get_image()
	var ink_pixels := 0
	var gold_pixels := 0
	var amber_like_pixels := 0
	var cool_pixels := 0
	var magenta_pixels := 0
	var opaque_pixels := 0
	for pixel_y in range(0, body_image.get_height(), 4):
		for pixel_x in range(0, body_image.get_width(), 4):
			var pixel := body_image.get_pixel(pixel_x, pixel_y)
			if pixel.a < 0.5:
				continue
			opaque_pixels += 1
			var luma := pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11
			if luma < 0.22:
				ink_pixels += 1
			if pixel.r > pixel.g and pixel.g > pixel.b + 0.04 and pixel.g > 0.28:
				gold_pixels += 1
			if pixel.r > pixel.b + 0.12 and pixel.r > pixel.g - 0.02 and pixel.r > 0.55:
				amber_like_pixels += 1
			if pixel.b > pixel.r + 0.04 or pixel.g > pixel.r + 0.08:
				cool_pixels += 1
			if pixel.r > 0.4 and pixel.b > 0.4 and pixel.g < pixel.r - 0.12:
				magenta_pixels += 1
	if opaque_pixels == 0 or float(ink_pixels) / float(opaque_pixels) < 0.55:
		printerr("商人星球地面应偏墨色")
		failed += 1
	if gold_pixels == 0:
		printerr("商人星球地面应有金色账本线")
		failed += 1
	if float(amber_like_pixels) / float(opaque_pixels) > 0.35:
		printerr("商人星球地面不应像酒鬼琥珀")
		failed += 1
	if float(cool_pixels) / float(opaque_pixels) > 0.2:
		printerr("商人星球地面不应偏国王那颗的绿蓝")
		failed += 1
	if magenta_pixels > 0:
		printerr("商人星球地面不应偏虚荣者洋红")
		failed += 1
	var ink_zenith := (
			planet.sky.material as ShaderMaterial
	).get_shader_parameter("zenith_gradient") as GradientTexture1D
	if ink_zenith == null:
		printerr("商人星球应有墨金夜空")
		failed += 1
	else:
		var midnight := ink_zenith.gradient.sample(0.0)
		var noon := ink_zenith.gradient.sample(SkyPhase.NOON_PHASE)
		if midnight.r > 0.2 or midnight.g > 0.2 or midnight.b > 0.22:
			printerr("商人午夜天空应偏墨色，实际 %s" % midnight)
			failed += 1
		if noon.g > noon.r and noon.g > noon.b:
			printerr("商人天空不应像国王正午绿天，实际 %s" % noon)
			failed += 1
		if noon.r > noon.b + 0.2 and noon.r > 0.45:
			printerr("商人天空不应像酒鬼琥珀傍晚，实际 %s" % noon)
			failed += 1
	var star_alpha := (
			load("res://planet/night_sky_gradient.tres") as GradientTexture1D
	).gradient.sample(0.0).r
	if star_alpha < 0.9:
		printerr("午夜相位应能看见星星")
		failed += 1

	if merchant == null or star_jar == null:
		scene.queue_free()
		await process_frame
		return failed + 1

	failed += _assert_focus(planet, star_jar, &"star_jar", "装星星的玻璃罐")
	planet.teleport_player(planet.spawn_angle)
	story.skip_cinematics = true
	await story.start()
	if not is_equal_approx(planet.sky.daylight_phase(), 0.0):
		printerr("商人星球天光应锁在午夜以便看见星星")
		failed += 1
	if not story.has_crossed_sunset:
		printerr("商人章不应再追日落")
		failed += 1
	if not story.has_finished_opening:
		printerr("商人开场结束后应能走动")
		failed += 1
	if story.is_blocking_input:
		printerr("商人开场结束后应允许走动")
		failed += 1
	if not player.can_move_left or not player.can_move_right:
		printerr("商人开场后应能左右移动")
		failed += 1
	var merchant_offset := merchant.offset
	var merchant_flip := merchant.flip_h
	var merchant_texture := merchant.texture
	story.skip_cinematics = false
	await story._camera_up()
	var camera := scene.get_node("%GameCamera") as Camera2D
	if camera.offset.y > -8.0:
		printerr("玩家抬头后镜头应抬向星空")
		failed += 1
	if (
			merchant.offset != merchant_offset
			or merchant.flip_h != merchant_flip
			or merchant.texture != merchant_texture
	):
		printerr("玩家抬头时商人不应抬头")
		failed += 1
	await story._camera_down()
	Input.action_press(&"move_up")
	for _frame_index in 24:
		story._process(0.016)
	if camera.offset.y > -8.0:
		printerr("按上应能抬头看天上的星星")
		failed += 1
	if merchant.offset != merchant_offset or merchant.flip_h != merchant_flip:
		printerr("玩家按上抬头时商人仍不应抬头")
		failed += 1
	Input.action_release(&"move_up")
	story.skip_cinematics = true
	if not story.accepts_interact(star_jar):
		printerr("开场后应能点玻璃罐")
		failed += 1
	if story.accepts_interact(merchant):
		printerr("不应把商人做成清点/交易对象")
		failed += 1
	if not story.try_handle_interact(star_jar):
		printerr("开场后应一点玻璃罐即过")
		failed += 1
	if not star_jar.is_consumed:
		printerr("点过玻璃罐后应消耗，不要反复清点")
		failed += 1
	if player.modulate.a > 0.01:
		printerr("离星后小王子应消失")
		failed += 1
	if story.get_node("%Epilogue").text != "328。":
		printerr("黑场应留下 328。，实际 %s" % story.get_node("%Epilogue").text)
		failed += 1
	if FileAccess.get_file_as_string("res://story/merchant_story.gd").contains("_interact(") \
			and FileAccess.get_file_as_string("res://story/merchant_story.gd").count("_interact(") != 1:
		printerr("商人章只能点一次玻璃罐")
		failed += 1
	if failed == 0:
		print("  商人星球演出 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_drunkard_departed_travels_to_merchant() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("%Story") as B612Story).auto_start = false
	(scene.get_node("%KingStory") as KingStory).skip_cinematics = true
	(scene.get_node("%DrunkardStory") as DrunkardStory).skip_cinematics = true
	(scene.get_node("%MerchantStory") as MerchantStory).skip_cinematics = true
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_drunkard_planet(true)
	await process_frame
	await process_frame
	var drunkard_story := scene.get_node("%DrunkardStory") as DrunkardStory
	drunkard_story._story_generation += 1
	drunkard_story.is_active = false
	drunkard_story.set_process(false)
	drunkard_story.departed.emit()
	await process_frame
	await process_frame
	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var merchant_story := scene.get_node("%MerchantStory") as MerchantStory
	if planet == null or planet.scene_file_path != "res://planet/merchant.tscn":
		printerr(
				"酒鬼离星后应换到商人星球，实际 %s"
				% (planet.scene_file_path if planet != null else "null")
		)
		failed += 1
	if merchant_story.planet != planet:
		printerr("离星换星后 MerchantStory 应绑定商人星球")
		failed += 1
	failed += _assert_playing_music(scene, "merchant_day_music", "酒鬼离星换星")
	var opening_deadline_msec := Time.get_ticks_msec() + 5000
	while (
			not merchant_story.has_finished_opening
			and Time.get_ticks_msec() < opening_deadline_msec
	):
		await process_frame
	if not merchant_story.has_finished_opening:
		printerr("换星后商人开场应自动开始")
		failed += 1
	if failed == 0:
		print("  酒鬼离星后进入商人星球 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_lamplighter_chapter() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_king_planet(false)
	await process_frame
	scene.travel_to_drunkard_planet(false)
	await process_frame
	scene.travel_to_merchant_planet(false)
	await process_frame
	scene.travel_to_lamplighter_planet(false)
	await process_frame

	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var player: Player = scene.get_node_or_null(PLAYER_PATH) as Player
	var story := scene.get_node_or_null("%LamplighterStory") as LamplighterStory
	if planet == null or player == null or story == null:
		printerr("点灯人章缺少 Planet / Player / LamplighterStory")
		scene.queue_free()
		await process_frame
		return 1
	if planet.scene_file_path != "res://planet/lamplighter.tscn":
		printerr("商人之后星球应为 lamplighter.tscn，实际 %s" % planet.scene_file_path)
		failed += 1
	failed += _assert_playing_music(scene, "lamplighter_day_music", "换到点灯人星球")
	if story.planet != planet:
		printerr("换星后 LamplighterStory 应绑定点灯人星球")
		failed += 1
	if (scene.get_node("%Interaction") as Interaction).story != story:
		printerr("换星后 Interaction 应绑定 LamplighterStory")
		failed += 1
	if not is_equal_approx(planet.radius, WorldConstants.LAMPLIGHTER_PLANET_RADIUS):
		printerr("点灯人星球半径应更小")
		failed += 1
	if not is_equal_approx(
			planet.sky.star_rotation_speed,
			WorldConstants.LAMPLIGHTER_STAR_ROTATION_SPEED
	):
		printerr("点灯人星空自转应极快")
		failed += 1

	var lamplighter: SurfaceProp = null
	var street_lamp: SurfaceProp = null
	var lamp_count := 0
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.LAMPLIGHTER:
				lamplighter = prop
				if prop.is_interactable() or story.accepts_interact(prop):
					printerr("点灯人不应可交互")
					failed += 1
			SurfaceProp.Kind.STREET_LAMP:
				street_lamp = prop
				lamp_count += 1
			SurfaceProp.Kind.KING, SurfaceProp.Kind.ROSE, SurfaceProp.Kind.DRUNKARD, SurfaceProp.Kind.BOTTLE, SurfaceProp.Kind.MERCHANT, SurfaceProp.Kind.STAR_JAR, SurfaceProp.Kind.VOLCANO, SurfaceProp.Kind.BAOBAB, SurfaceProp.Kind.FLORA:
				printerr("点灯人星球不应有其它章地物 %s" % prop.name)
				failed += 1
	if lamplighter == null:
		printerr("点灯人星球应有点灯人")
		failed += 1
	if lamp_count != 1 or street_lamp == null:
		printerr("点灯人星球应只有一盏灯")
		failed += 1

	var body_image := (planet.body.texture as Texture2D).get_image()
	var chroma_pixels := 0
	var opaque_pixels := 0
	for pixel_y in range(0, body_image.get_height(), 4):
		for pixel_x in range(0, body_image.get_width(), 4):
			var pixel := body_image.get_pixel(pixel_x, pixel_y)
			if pixel.a < 0.5:
				continue
			opaque_pixels += 1
			var chroma := absf(pixel.r - pixel.g) + absf(pixel.g - pixel.b) + absf(pixel.b - pixel.r)
			if chroma > 0.08:
				chroma_pixels += 1
	if opaque_pixels == 0 or float(chroma_pixels) / float(opaque_pixels) > 0.05:
		printerr("点灯人星球地面应是黑白灰")
		failed += 1
	var gray_zenith := (
			planet.sky.material as ShaderMaterial
	).get_shader_parameter("zenith_gradient") as GradientTexture1D
	if gray_zenith == null:
		printerr("点灯人星球应有灰阶天空")
		failed += 1
	else:
		var midnight := gray_zenith.gradient.sample(0.0)
		var noon := gray_zenith.gradient.sample(SkyPhase.NOON_PHASE)
		var midnight_chroma := (
				absf(midnight.r - midnight.g)
				+ absf(midnight.g - midnight.b)
				+ absf(midnight.b - midnight.r)
		)
		var noon_chroma := absf(noon.r - noon.g) + absf(noon.g - noon.b) + absf(noon.b - noon.r)
		if midnight_chroma > 0.04 or noon_chroma > 0.04:
			printerr("点灯人天空应为灰阶，午夜 %s 正午 %s" % [midnight, noon])
			failed += 1
		if noon.r <= midnight.r + 0.2:
			printerr("点灯人正午应明显亮于午夜")
			failed += 1
		if noon.g > noon.r and noon.g > noon.b:
			printerr("点灯人天空不应像国王正午绿天")
			failed += 1
		if noon.r > noon.b + 0.2 and noon.r > 0.45:
			printerr("点灯人天空不应像酒鬼琥珀傍晚")
			failed += 1

	if lamplighter == null or street_lamp == null:
		scene.queue_free()
		await process_frame
		return failed + 1

	var night_started_count := 0
	var was_night := SkyPhase.is_night_phase(planet.sky.daylight_phase())
	var simulated_seconds := 0.0
	var step_seconds := 0.05
	var three_days_seconds := (
			TAU / WorldConstants.LAMPLIGHTER_STAR_ROTATION_SPEED
			* float(LamplighterStory.ACCOMPANY_DAY_NIGHT_ROUND_COUNT)
	)
	while simulated_seconds < three_days_seconds + step_seconds:
		planet.sky._process(step_seconds)
		simulated_seconds += step_seconds
		var is_night := SkyPhase.is_night_phase(planet.sky.daylight_phase())
		if is_night and not was_night:
			night_started_count += 1
		was_night = is_night
	if night_started_count < LamplighterStory.ACCOMPANY_DAY_NIGHT_ROUND_COUNT:
		printerr(
				"极快昼夜应能陪过几轮，实际入夜 %d"
				% night_started_count
		)
		failed += 1

	failed += _assert_focus(planet, street_lamp, &"street_lamp", "路灯")
	planet.teleport_player(planet.spawn_angle)
	story.skip_cinematics = true
	await story.start()
	if not story.has_finished_opening:
		printerr("点灯人开场结束后应能走动")
		failed += 1
	if story.is_blocking_input:
		printerr("点灯人开场结束后应允许走动")
		failed += 1
	if not player.can_move_left or not player.can_move_right:
		printerr("点灯人开场后应能左右移动")
		failed += 1
	if not story.accepts_interact(street_lamp):
		printerr("开场后应能帮点一次灯")
		failed += 1
	if story.accepts_interact(lamplighter):
		printerr("不应把点灯人做成修好作息的对象")
		failed += 1
	if not story.try_handle_interact(street_lamp):
		printerr("开场后应能帮点一次灯")
		failed += 1
	if not street_lamp.is_consumed:
		printerr("帮点一次后灯交互应消耗")
		failed += 1
	if story.accepts_interact(street_lamp):
		printerr("不能反复点灯当成把灯点完的关卡")
		failed += 1
	if not is_equal_approx(
			planet.sky.star_rotation_speed,
			WorldConstants.LAMPLIGHTER_STAR_ROTATION_SPEED
	):
		printerr("帮点一次后作息不应被调慢")
		failed += 1
	planet.sky.is_self_rotating = false
	planet.sky.commanded_daylight_phase = SkyPhase.NOON_PHASE
	await process_frame
	if street_lamp.frame != 0:
		printerr("白天灯应熄，作息没有被修好")
		failed += 1
	planet.sky.commanded_daylight_phase = 0.0
	await process_frame
	if street_lamp.frame != 1:
		printerr("夜里灯应亮，离开时作息仍在转")
		failed += 1
	if player.modulate.a > 0.01:
		printerr("离星后小王子应消失")
		failed += 1
	if story.get_node("%Epilogue").text != "329。":
		printerr("黑场应留下 329。，实际 %s" % story.get_node("%Epilogue").text)
		failed += 1
	if FileAccess.get_file_as_string("res://story/lamplighter_story.gd").count("_interact(") != 1:
		printerr("点灯人章只能帮点一次灯")
		failed += 1
	if failed == 0:
		print("  点灯人星球演出 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_merchant_departed_travels_to_lamplighter() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("%Story") as B612Story).auto_start = false
	(scene.get_node("%KingStory") as KingStory).skip_cinematics = true
	(scene.get_node("%DrunkardStory") as DrunkardStory).skip_cinematics = true
	(scene.get_node("%MerchantStory") as MerchantStory).skip_cinematics = true
	(scene.get_node("%LamplighterStory") as LamplighterStory).skip_cinematics = true
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_merchant_planet(true)
	await process_frame
	await process_frame
	var merchant_story := scene.get_node("%MerchantStory") as MerchantStory
	merchant_story._story_generation += 1
	merchant_story.is_active = false
	merchant_story.set_process(false)
	merchant_story.departed.emit()
	await process_frame
	await process_frame
	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var lamplighter_story := scene.get_node("%LamplighterStory") as LamplighterStory
	if planet == null or planet.scene_file_path != "res://planet/lamplighter.tscn":
		printerr(
				"商人离星后应换到点灯人星球，实际 %s"
				% (planet.scene_file_path if planet != null else "null")
		)
		failed += 1
	if lamplighter_story.planet != planet:
		printerr("离星换星后 LamplighterStory 应绑定点灯人星球")
		failed += 1
	failed += _assert_playing_music(scene, "lamplighter_day_music", "商人离星换星")
	var opening_deadline_msec := Time.get_ticks_msec() + 5000
	while (
			not lamplighter_story.has_finished_opening
			and Time.get_ticks_msec() < opening_deadline_msec
	):
		await process_frame
	if not lamplighter_story.has_finished_opening:
		printerr("换星后点灯人开场应自动开始")
		failed += 1
	if failed == 0:
		print("  商人离星后进入点灯人星球 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_geographer_chapter() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("GameView/GameViewport/Story") as B612Story).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_king_planet(false)
	await process_frame
	scene.travel_to_drunkard_planet(false)
	await process_frame
	scene.travel_to_merchant_planet(false)
	await process_frame
	scene.travel_to_lamplighter_planet(false)
	await process_frame
	scene.travel_to_geographer_planet(false)
	await process_frame

	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var player: Player = scene.get_node_or_null(PLAYER_PATH) as Player
	var story := scene.get_node_or_null("%GeographerStory") as GeographerStory
	if planet == null or player == null or story == null:
		printerr("地理学家章缺少 Planet / Player / GeographerStory")
		scene.queue_free()
		await process_frame
		return 1
	if planet.scene_file_path != "res://planet/geographer.tscn":
		printerr("点灯人之后星球应为 geographer.tscn，实际 %s" % planet.scene_file_path)
		failed += 1
	failed += _assert_playing_music(scene, "geographer_day_music", "换到地理学家星球")
	if story.planet != planet:
		printerr("换星后 GeographerStory 应绑定地理学家星球")
		failed += 1
	if (scene.get_node("%Interaction") as Interaction).story != story:
		printerr("换星后 Interaction 应绑定 GeographerStory")
		failed += 1
	if FileAccess.file_exists("res://planet/earth.tscn"):
		printerr("地球关卡这轮仍不应存在")
		failed += 1

	var geographer: SurfaceProp = null
	var report_count := 0
	for prop in planet.surface_props:
		match prop.kind:
			SurfaceProp.Kind.GEOGRAPHER:
				geographer = prop
			SurfaceProp.Kind.INK_REPORT:
				report_count += 1
				if prop.is_interactable() or story.accepts_interact(prop):
					printerr("报告堆只是书房陈设，不应可交互")
					failed += 1
			SurfaceProp.Kind.KING, SurfaceProp.Kind.ROSE, SurfaceProp.Kind.DRUNKARD, SurfaceProp.Kind.BOTTLE, SurfaceProp.Kind.MERCHANT, SurfaceProp.Kind.STAR_JAR, SurfaceProp.Kind.LAMPLIGHTER, SurfaceProp.Kind.STREET_LAMP, SurfaceProp.Kind.VOLCANO, SurfaceProp.Kind.BAOBAB, SurfaceProp.Kind.FLORA:
				printerr("地理学家星球不应有风景或其它章地物 %s" % prop.name)
				failed += 1
	if geographer == null:
		printerr("地理学家星球应有地理学家")
		failed += 1
	if report_count != WorldConstants.GEOGRAPHER_REPORT_STACK_COUNT:
		printerr(
				"书房报告堆应为 %d，实际 %d"
				% [WorldConstants.GEOGRAPHER_REPORT_STACK_COUNT, report_count]
		)
		failed += 1

	var body_image := (planet.body.texture as Texture2D).get_image()
	var cream_pixels := 0
	var ink_pixels := 0
	var cool_pixels := 0
	var gray_pixels := 0
	var amber_like_pixels := 0
	var dark_ink_ground_pixels := 0
	var opaque_pixels := 0
	for pixel_y in range(0, body_image.get_height(), 4):
		for pixel_x in range(0, body_image.get_width(), 4):
			var pixel := body_image.get_pixel(pixel_x, pixel_y)
			if pixel.a < 0.5:
				continue
			opaque_pixels += 1
			var luma := pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11
			var chroma := absf(pixel.r - pixel.g) + absf(pixel.g - pixel.b) + absf(pixel.b - pixel.r)
			if pixel.r > 0.55 and pixel.g > 0.42 and pixel.r > pixel.b and pixel.g > pixel.b:
				cream_pixels += 1
			if pixel.r > pixel.g + 0.04 and pixel.g > pixel.b and luma < 0.45:
				ink_pixels += 1
			if pixel.b > pixel.r + 0.04 or pixel.g > pixel.r + 0.08:
				cool_pixels += 1
			if chroma < 0.08:
				gray_pixels += 1
			if pixel.r > pixel.g + 0.12 and pixel.r > 0.55 and pixel.b < 0.28:
				amber_like_pixels += 1
			if luma < 0.22:
				dark_ink_ground_pixels += 1
	if opaque_pixels == 0 or float(cream_pixels) / float(opaque_pixels) < 0.45:
		printerr("地理学家星球地面应是羊皮纸")
		failed += 1
	if ink_pixels == 0:
		printerr("羊皮纸上应有墨迹报告")
		failed += 1
	if float(cool_pixels) / float(opaque_pixels) > 0.2:
		printerr("羊皮纸地面不应偏国王那颗的绿蓝")
		failed += 1
	if float(gray_pixels) / float(opaque_pixels) > 0.25:
		printerr("羊皮纸地面不应像点灯人灰地")
		failed += 1
	if float(amber_like_pixels) / float(opaque_pixels) > 0.35:
		printerr("羊皮纸地面不应像酒鬼琥珀")
		failed += 1
	if float(dark_ink_ground_pixels) / float(opaque_pixels) > 0.35:
		printerr("羊皮纸地面不应像商人墨色账本")
		failed += 1
	var parchment_zenith := (
			planet.sky.material as ShaderMaterial
	).get_shader_parameter("zenith_gradient") as GradientTexture1D
	if parchment_zenith == null:
		printerr("地理学家星球应有羊皮纸书房天空")
		failed += 1
	else:
		var midnight := parchment_zenith.gradient.sample(0.0)
		var noon := parchment_zenith.gradient.sample(SkyPhase.NOON_PHASE)
		if noon.g > noon.r and noon.g > noon.b:
			printerr("地理学家天空不应像国王正午绿天，实际 %s" % noon)
			failed += 1
		if noon.r > noon.g + 0.2 and noon.r > 0.45:
			printerr("地理学家天空不应像酒鬼琥珀傍晚，实际 %s" % noon)
			failed += 1
		if midnight.r < 0.05 and midnight.g < 0.05 and midnight.b < 0.05:
			printerr("地理学家午夜不应是商人那种墨黑")
			failed += 1
		var noon_chroma := absf(noon.r - noon.g) + absf(noon.g - noon.b) + absf(noon.b - noon.r)
		if noon_chroma < 0.08:
			printerr("地理学家天空不应是点灯人灰阶")
			failed += 1

	if geographer == null:
		scene.queue_free()
		await process_frame
		return failed + 1

	failed += _assert_focus(planet, geographer, &"geographer", "地理学家")
	planet.teleport_player(planet.spawn_angle)
	story.skip_cinematics = true
	await story.start()
	if not story.has_crossed_sunset:
		printerr("地理学家章不应再追日落")
		failed += 1
	if not story.has_finished_opening:
		printerr("地理学家开场结束后应能走动")
		failed += 1
	if story.is_blocking_input:
		printerr("地理学家开场结束后应允许走动")
		failed += 1
	if not player.can_move_left or not player.can_move_right:
		printerr("地理学家开场后应能左右移动")
		failed += 1
	if not story.accepts_interact(geographer):
		printerr("开场后应能与地理学家说话")
		failed += 1
	if not story.try_handle_interact(geographer):
		printerr("开场后应能与地理学家说话")
		failed += 1
	if not geographer.is_consumed:
		printerr("说完后不应把玫瑰记进报告")
		failed += 1
	if player.modulate.a > 0.01:
		printerr("指向地球后戏应停，小王子应消失")
		failed += 1
	if story.get_node("%Epilogue").text != "330。":
		printerr("黑场应留下 330。，实际 %s" % story.get_node("%Epilogue").text)
		failed += 1
	if planet.scene_file_path == "res://planet/earth.tscn":
		printerr("指向地球后不应载入地球关卡")
		failed += 1
	var story_source := FileAccess.get_file_as_string("res://story/geographer_story.gd")
	if not story_source.contains("我不记"):
		printerr("地理学家应拒绝记下玫瑰")
		failed += 1
	if not story_source.contains("他指向地球。"):
		printerr("演出应在指向地球时停")
		failed += 1
	if story_source.find("我不记") > story_source.find("他指向地球。"):
		printerr("应先拒绝玫瑰，再指向地球")
		failed += 1
	if story_source.count("_interact(") != 1:
		printerr("地理学家章只与地理学家谈一次")
		failed += 1
	if failed == 0:
		print("  地理学家星球演出 OK")
	scene.queue_free()
	await process_frame
	return failed


func _check_lamplighter_departed_travels_to_geographer() -> int:
	var failed := 0
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		return 1
	var scene := packed.instantiate()
	(
		scene.get_node("GameView/GameViewport/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node("%Story") as B612Story).auto_start = false
	(scene.get_node("%KingStory") as KingStory).skip_cinematics = true
	(scene.get_node("%DrunkardStory") as DrunkardStory).skip_cinematics = true
	(scene.get_node("%MerchantStory") as MerchantStory).skip_cinematics = true
	(scene.get_node("%LamplighterStory") as LamplighterStory).skip_cinematics = true
	(scene.get_node("%GeographerStory") as GeographerStory).skip_cinematics = true
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.travel_to_lamplighter_planet(true)
	await process_frame
	await process_frame
	var lamplighter_story := scene.get_node("%LamplighterStory") as LamplighterStory
	lamplighter_story._story_generation += 1
	lamplighter_story.is_active = false
	lamplighter_story.set_process(false)
	lamplighter_story.departed.emit()
	await process_frame
	await process_frame
	var planet: Planet = scene.get_node_or_null(PLANET_PATH) as Planet
	var geographer_story := scene.get_node("%GeographerStory") as GeographerStory
	if planet == null or planet.scene_file_path != "res://planet/geographer.tscn":
		printerr(
				"点灯人离星后应换到地理学家星球，实际 %s"
				% (planet.scene_file_path if planet != null else "null")
		)
		failed += 1
	if geographer_story.planet != planet:
		printerr("离星换星后 GeographerStory 应绑定地理学家星球")
		failed += 1
	failed += _assert_playing_music(scene, "geographer_day_music", "点灯人离星换星")
	var opening_deadline_msec := Time.get_ticks_msec() + 5000
	while (
			not geographer_story.has_finished_opening
			and Time.get_ticks_msec() < opening_deadline_msec
	):
		await process_frame
	if not geographer_story.has_finished_opening:
		printerr("换星后地理学家开场应自动开始")
		failed += 1
	if planet != null and planet.scene_file_path == "res://planet/earth.tscn":
		printerr("点灯人之后不应进入地球关卡")
		failed += 1
	if failed == 0:
		print("  点灯人离星后进入地理学家星球 OK")
	scene.queue_free()
	await process_frame
	return failed

