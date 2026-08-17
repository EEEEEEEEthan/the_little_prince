class_name PropScreenOverlay
extends Node2D
## 屏幕空间地物叠加层：画在 PlanetView 之上。
##
## SubViewport 只渲染地面 + 小王子；地物用与鱼眼 shader 同一套逆投影
## 投到屏幕，再沿屏幕径向做 stacked lean。高层可落到 r>1，戳进星空。

## 来自 WorldGenerator 的地物描述（完整列表，供数量断言）
var props: Array[StackedProp] = []
## 每帧由 Main 写入
var player_uv: Vector2 = Vector2(0.5, 0.5)
var view_size: Vector2 = Vector2(960, 960)
var curvature: float = SphereProjection.DEFAULT_CURVATURE
var view_span: float = SphereProjection.DEFAULT_VIEW_SPAN

## 与视觉一一对应的有效地物
var _active_props: Array[StackedProp] = []
## 每个地物一个根节点，内含底→顶 Sprite2D
var _visual_roots: Array[Node2D] = []
var _layer_sprites: Array = [] # Array[Array[Sprite2D]]
var _built: bool = false

func set_props(stacked: Array[StackedProp]) -> void:
	props = stacked
	_rebuild()

func prop_visual_count() -> int:
	return _visual_roots.size()

func _ready() -> void:
	z_as_relative = false
	z_index = 20
	set_process(true)

func _process(_delta: float) -> void:
	if not _built:
		return
	_update_all()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_visual_roots.clear()
	_layer_sprites.clear()
	_active_props.clear()
	_built = false

	for prop in props:
		if prop == null or prop.layer_textures.is_empty():
			continue
		var root := Node2D.new()
		root.name = "PropVisual_%s" % prop.name
		root.rotation = 0.0
		add_child(root)
		_visual_roots.append(root)
		_active_props.append(prop)

		var layers: Array[Sprite2D] = []
		for i in prop.layer_textures.size():
			var sprite := Sprite2D.new()
			sprite.texture = prop.layer_textures[i]
			sprite.centered = true
			sprite.rotation = 0.0
			sprite.position = Vector2.ZERO
			sprite.z_as_relative = true
			sprite.z_index = i
			root.add_child(sprite)
			layers.append(sprite)
		_layer_sprites.append(layers)

	_built = not _visual_roots.is_empty()
	if _built:
		_update_all()

func _update_all() -> void:
	var size := Vector2(maxf(view_size.x, 1.0), maxf(view_size.y, 1.0))
	var min_side := minf(size.x, size.y)
	# 先算投影，再按 r 远→近排序赋 z（远的更低 z，先画）
	var order: Array[Dictionary] = []
	for i in _visual_roots.size():
		var prop: StackedProp = _active_props[i]
		var proj := SphereProjection.world_to_screen(
			prop.world_uv(),
			player_uv,
			size,
			curvature,
			view_span
		)
		order.append({"i": i, "r": float(proj["r"]), "proj": proj})

	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["r"]) > float(b["r"])
	)

	var draw_slot := 0
	for entry in order:
		var i: int = int(entry["i"])
		var proj: Dictionary = entry["proj"]
		var prop: StackedProp = _active_props[i]
		var root: Node2D = _visual_roots[i]
		var layers: Array = _layer_sprites[i]

		if not bool(proj["visible"]):
			root.visible = false
			continue
		root.visible = true

		var screen_pos: Vector2 = proj["screen_pos"]
		var dir: Vector2 = proj["dir"]
		var lean: float = float(proj["lean"])
		# 与 pitch 同一套尺度：贴图像素对齐星球表面；pitch 另乘凸出放大
		var sprite_scale := SphereProjection.world_to_screen_scale(
			min_side, view_span, curvature
		)
		var screen_pitch := SphereProjection.world_pitch_to_screen(
			prop.pitch, min_side, view_span, curvature
		)

		root.position = screen_pos
		root.rotation = 0.0
		root.z_as_relative = false
		root.z_index = 20 + draw_slot * 32

		for li in layers.size():
			var sprite: Sprite2D = layers[li]
			# 切片保持正立；尺寸随 view_size 更新；沿屏幕径向偏移
			sprite.rotation = 0.0
			sprite.scale = Vector2(sprite_scale, sprite_scale)
			sprite.position = dir * screen_pitch * float(li) * lean
			sprite.z_index = li
		draw_slot += 1

## 供测试：返回某地物顶层相对锚点的屏幕偏移与有效 r
func debug_top_layer_state(prop_index: int) -> Dictionary:
	if prop_index < 0 or prop_index >= _active_props.size() or prop_index >= _layer_sprites.size():
		return {"ok": false}
	var prop: StackedProp = _active_props[prop_index]
	var size := Vector2(maxf(view_size.x, 1.0), maxf(view_size.y, 1.0))
	var min_side := minf(size.x, size.y)
	var proj := SphereProjection.world_to_screen(
		prop.world_uv(), player_uv, size, curvature, view_span
	)
	if not bool(proj["visible"]):
		return {"ok": true, "visible": false, "proj": proj}
	var layers: Array = _layer_sprites[prop_index]
	var top_i := layers.size() - 1
	var top: Sprite2D = layers[top_i]
	var sprite_scale := SphereProjection.world_to_screen_scale(min_side, view_span, curvature)
	var screen_pitch := SphereProjection.world_pitch_to_screen(
		prop.pitch, min_side, view_span, curvature
	)
	var lean: float = float(proj["lean"])
	var r_eff := SphereProjection.effective_screen_r(
		float(proj["r"]), lean, screen_pitch, top_i, min_side
	)
	return {
		"ok": true,
		"visible": true,
		"proj": proj,
		"top_position": top.position,
		"top_scale": top.scale,
		"sprite_scale": sprite_scale,
		"screen_pitch": screen_pitch,
		"lean": lean,
		"r_effective": r_eff,
	}
