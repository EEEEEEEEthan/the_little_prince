extends SceneTree
## 头无模式验证脚本：检查世界常量、环面 wrap、场景可加载、地物数量、
## InputMap 动作、shader 无边缘辉光、SphereProjection 逆映射、屏幕叠加凸出。
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
	failed += _check_sphere_projection()
	failed += _check_screen_stack_protrusion()
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
	if WorldConstants.STACK_SCREEN_PITCH_SCALE <= 0.0:
		printerr("STACK_SCREEN_PITCH_SCALE 应 > 0")
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

func _check_sphere_projection() -> int:
	## SphereProjection：球心→中心；正右 UV → r>0 且 x>中心；背面隐藏
	var failed := 0
	var view := Vector2(960, 960)
	var center := view * 0.5
	var player_uv := Vector2(0.5, 0.5)
	var curv := SphereProjection.DEFAULT_CURVATURE
	var span := SphereProjection.DEFAULT_VIEW_SPAN

	# 1) 球心
	var c := SphereProjection.world_to_screen(player_uv, player_uv, view, curv, span)
	if not bool(c["visible"]):
		printerr("球心地物应可见")
		failed += 1
	if Vector2(c["screen_pos"]).distance_to(center) > 0.5:
		printerr("球心应映射到屏幕中心：%s" % c["screen_pos"])
		failed += 1
	if float(c["r"]) > 1e-4 or float(c["lean"]) > 1e-4:
		printerr("球心 r/lean 应≈0：r=%s lean=%s" % [c["r"], c["lean"]])
		failed += 1

	# 2) 正右方 UV 偏移
	var right_uv := player_uv + Vector2(0.08, 0.0)
	var rgt := SphereProjection.world_to_screen(right_uv, player_uv, view, curv, span)
	if not bool(rgt["visible"]):
		printerr("正右方地物应可见")
		failed += 1
	if float(rgt["r"]) <= 0.0:
		printerr("正右方 r 应 > 0，实际 %s" % rgt["r"])
		failed += 1
	if Vector2(rgt["screen_pos"]).x <= center.x:
		printerr("正右方屏幕 x 应 > 中心：%s" % rgt["screen_pos"])
		failed += 1
	if absf(Vector2(rgt["dir"]).y) > 0.05 or Vector2(rgt["dir"]).x <= 0.0:
		printerr("正右方 dir 应≈(+1,0)：%s" % rgt["dir"])
		failed += 1

	# 3) 环面最短：从 0.95 到 0.05 应走短边（向右），而非绕整圈
	var wrap_delta := SphereProjection.torus_delta_uv(Vector2(0.05, 0.5), Vector2(0.95, 0.5))
	if wrap_delta.x <= 0.0 or wrap_delta.x > 0.2:
		printerr("环面 UV 最短差错误：%s" % wrap_delta)
		failed += 1

	# 4) 超出可视半球（越过剪影 / z<=0）→ 不可见
	# 剪影处 offset ≈ (HALF_PI*curvature)/HALF_PI*(view_span*0.5) = curvature*view_span*0.5
	var horizon := curv * span * 0.5
	var back_uv := player_uv + Vector2(horizon + 0.02, 0.0)
	var back := SphereProjection.world_to_screen(back_uv, player_uv, view, curv, span)
	if bool(back["visible"]):
		printerr("背面地物应不可见，实际 visible=true r=%s" % back["r"])
		failed += 1

	if failed == 0:
		print("  SphereProjection 逆映射 OK")
	return failed

func _check_screen_stack_protrusion() -> int:
	## 边缘 lean 下顶层屏幕偏移可使 r_effective > 1（凸出剪影）
	var failed := 0
	var view := Vector2(960, 960)
	var min_side := minf(view.x, view.y)
	var span := SphereProjection.DEFAULT_VIEW_SPAN
	var curv := SphereProjection.DEFAULT_CURVATURE
	var player_uv := Vector2(0.5, 0.5)

	# 用火山级 pitch + 层数，在接近边缘的 UV 上验证凸出
	var pitch := WorldConstants.VOLCANO_PITCH
	var layers := WorldConstants.VOLCANO_LAYER_COUNT
	var top_i := layers - 1
	var screen_per_world := SphereProjection.world_to_screen_scale(min_side, span, curv)
	var screen_pitch := SphereProjection.world_pitch_to_screen(pitch, min_side, span, curv)

	# 短边 960 时，世界→屏幕尺度应明显 >1（约 4～5×）
	if screen_per_world <= 1.0:
		printerr("world_to_screen_scale 在 960 短边时应 >1，实际 %s" % screen_per_world)
		failed += 1
	if absf(screen_pitch - pitch * screen_per_world * WorldConstants.STACK_SCREEN_PITCH_SCALE) > 0.05:
		printerr(
			"pitch 换算应 = pitch * scale * boost：pitch=%s scale=%s 实际=%s"
			% [pitch, screen_per_world, screen_pitch]
		)
		failed += 1

	# 选一个贴近剪影内侧的 UV，使 r≈1、lean≈1，顶层必凸出
	var horizon := curv * span * 0.5
	var edge_uv := player_uv + Vector2(horizon * 0.97, 0.0)
	var proj := SphereProjection.world_to_screen(edge_uv, player_uv, view, curv, span)
	if not bool(proj["visible"]):
		printerr("边缘测试点应可见")
		failed += 1
		return failed

	var r := float(proj["r"])
	var lean := float(proj["lean"])
	if r < 0.9:
		printerr("边缘测试点 r 应接近 1，实际 %s" % r)
		failed += 1
	if lean < 0.85:
		printerr("边缘 lean 应接近 1，实际 %s" % lean)
		failed += 1

	var r_eff := SphereProjection.effective_screen_r(r, lean, screen_pitch, top_i, min_side)
	if r_eff <= 1.0:
		printerr(
			"边缘顶层应凸出圆外：r=%s lean=%s pitch=%s r_eff=%s"
			% [r, lean, screen_pitch, r_eff]
		)
		failed += 1

	# 球心 lean=0 → 顶层不偏移，r_eff=0
	var r0 := SphereProjection.effective_screen_r(0.0, 0.0, screen_pitch, top_i, min_side)
	if r0 > 1e-4:
		printerr("球心有效 r 应≈0，实际 %s" % r0)
		failed += 1

	# Overlay 行为：不旋转、径向偏移
	var prop := StackedProp.new()
	prop.configure(
		PixelArt.make_volcano_layers(36, layers),
		pitch,
		Vector2.ZERO,
		Vector2(edge_uv.x * float(WorldConstants.WORLD_PIXELS), 0.5 * float(WorldConstants.WORLD_PIXELS)),
		float(WorldConstants.WORLD_PIXELS)
	)
	var overlay := PropScreenOverlay.new()
	overlay.player_uv = player_uv
	overlay.view_size = view
	overlay.curvature = curv
	overlay.view_span = span
	var prop_list: Array[StackedProp] = []
	prop_list.append(prop)
	overlay.set_props(prop_list)

	var st: Dictionary = overlay.debug_top_layer_state(0)
	if not bool(st.get("ok", false)) or not bool(st.get("visible", false)):
		printerr("Overlay 边缘地物状态异常：%s" % st)
		failed += 1
	else:
		var top_pos: Vector2 = st["top_position"]
		var dir: Vector2 = st["proj"]["dir"]
		# 顶层应沿 dir（切片 rotation 在 update 里恒为 0）
		if top_pos.length() < 1.0:
			printerr("边缘顶层屏幕偏移过小：%s" % top_pos)
			failed += 1
		if top_pos.normalized().dot(dir) < 0.99:
			printerr("顶层偏移应沿屏幕径向：pos=%s dir=%s" % [top_pos, dir])
			failed += 1
		if float(st["r_effective"]) <= 1.0:
			printerr("Overlay r_effective 应 > 1，实际 %s" % st["r_effective"])
			failed += 1
		var top_scale: Vector2 = st["top_scale"]
		var expected_s: float = float(st["sprite_scale"])
		if expected_s <= 1.0:
			printerr("sprite_scale 在 960 短边时应 >1，实际 %s" % expected_s)
			failed += 1
		if absf(expected_s - screen_per_world) > 0.01:
			printerr("sprite_scale 应等于 screen_per_world：%s vs %s" % [expected_s, screen_per_world])
			failed += 1
		if absf(top_scale.x - expected_s) > 0.01 or absf(top_scale.y - expected_s) > 0.01:
			printerr("顶层 Sprite2D.scale 应为 (%s,%s)，实际 %s" % [expected_s, expected_s, top_scale])
			failed += 1

	overlay.free()
	# prop 未入树，用 queue_free 即可
	prop.queue_free()

	if failed == 0:
		print("  屏幕堆叠凸出（r_effective>1）OK")
	return failed

func _check_input_map() -> int:
	var failed := 0
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

	for action in InputSetup.ACTIONS:
		if not InputMap.has_action(action):
			printerr("场景加载后缺少 InputMap 动作：%s" % action)
			failed += 1

	var world: WorldGenerator = scene.get_node_or_null("WorldHost/WorldViewport/PlanetWorld") as WorldGenerator
	var expected_props: int = (
		WorldConstants.ROSE_COUNT + WorldConstants.VOLCANO_COUNT + WorldConstants.BAOBAB_COUNT
	)
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

		if world.stacked_props.size() != expected_props:
			printerr(
				"StackedProp 数量应为 %d，实际 %d"
				% [expected_props, world.stacked_props.size()]
			)
			failed += 1

		# Props 不进入球面可见层
		var props_node: Node2D = world.get_node_or_null("Props") as Node2D
		if props_node == null:
			printerr("找不到 Props 节点")
			failed += 1
		else:
			if props_node.visible:
				printerr("props_root 应不可见（地物不进球面贴图）")
				failed += 1
			var stacked_in_tree := 0
			for child in props_node.get_children():
				if child is StackedProp:
					stacked_in_tree += 1
					var sp: StackedProp = child
					if sp.layer_textures.size() < 3:
						printerr("StackedProp 层数过少：%d" % sp.layer_textures.size())
						failed += 1
			if stacked_in_tree != expected_props:
				printerr(
					"Props 下 StackedProp 节点数应为 %d，实际 %d"
					% [expected_props, stacked_in_tree]
				)
				failed += 1

	# Overlay 存在且地物数量正确
	var overlay: PropScreenOverlay = scene.get_node_or_null("PropScreenOverlay") as PropScreenOverlay
	if overlay == null:
		# main 用代码创建，可能挂在 Main 根上
		var main_n := scene as Node
		for child in main_n.get_children():
			if child is PropScreenOverlay:
				overlay = child
				break
	if overlay == null:
		printerr("找不到 PropScreenOverlay")
		failed += 1
	else:
		if overlay.prop_visual_count() != expected_props:
			printerr(
				"Overlay 地物视觉数应为 %d，实际 %d"
				% [expected_props, overlay.prop_visual_count()]
			)
			failed += 1
		if overlay.props.size() != expected_props:
			printerr(
				"Overlay.props 数量应为 %d，实际 %d"
				% [expected_props, overlay.props.size()]
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

	print("  场景与世界生成 OK（props 隐藏 + Overlay）")
	scene.queue_free()
	await process_frame
	return failed
