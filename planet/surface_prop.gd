class_name SurfaceProp
extends Sprite2D
## 圆弧星球上的地表地物，拖到 Planet 的 Surface 下即可。
## 位置、贴图、帧、层级均在 tscn 中定死；运行期仅按玩家角更新可见性。

enum Kind {
	ROSE,
	VOLCANO,
	BAOBAB,
	FLORA,
	KING,
	RAT,
	EDICT,
	BORDER,
	RAT_TRACE,
	THRONE,
	CAPE,
	BOTTLE,
	DRUNKARD,
	MERCHANT,
	STAR_JAR,
	LAMPLIGHTER,
	STREET_LAMP,
	GEOGRAPHER,
	INK_REPORT,
	RAT_HOLE,
}

@export var kind: Kind = Kind.ROSE
@export var variant: int = 0
## 对话目录 id；空则按 kind 回落。装饰性地物无对话。
@export var dialogue_id: StringName = &""
var is_consumed: bool = false:
	set(value):
		is_consumed = value
		if not is_node_ready():
			await ready
		for child in get_children():
			var trigger := child as PlayerTrigger
			if trigger != null:
				trigger.monitorable = not is_consumed


func get_dialogue_id() -> StringName:
	if dialogue_id != &"":
		return dialogue_id
	match kind:
		Kind.ROSE:
			return &"rose"
		Kind.BAOBAB:
			return &"baobab"
		Kind.KING:
			return &"king"
		Kind.DRUNKARD:
			return &"drunkard"
		Kind.STAR_JAR:
			return &"star_jar"
		Kind.STREET_LAMP:
			return &"street_lamp"
		Kind.GEOGRAPHER:
			return &"geographer"
	return &""


func is_interactable() -> bool:
	match kind:
		Kind.EDICT, Kind.BORDER, Kind.THRONE, Kind.CAPE, Kind.RAT_HOLE:
			return true
		Kind.VOLCANO, Kind.FLORA, Kind.RAT, Kind.RAT_TRACE, Kind.BOTTLE, Kind.MERCHANT, Kind.LAMPLIGHTER, Kind.INK_REPORT:
			return false
	return not is_consumed and get_dialogue_id() != &""


func emit_baobab_fragment_burst() -> void:
	if kind != Kind.BAOBAB:
		return
	var burst_root := Node2D.new()
	burst_root.name = "BaobabFragmentBurst"
	burst_root.add_to_group("tree_fragment_burst")
	burst_root.z_index = z_index + 1
	var container := get_parent()
	if container == null:
		burst_root.queue_free()
		return
	container.add_child(burst_root)
	burst_root.global_position = global_position
	burst_root.rotation = global_rotation
	var base_texture := texture as Texture2D
	if base_texture == null:
		burst_root.queue_free()
		return
	var shard_size: int = 1
	var source_width: int = int(base_texture.get_width())
	var source_height: int = int(base_texture.get_height())
	var frame_start_x: int = 0
	if hframes > 1:
		frame_start_x = int(frame) * (source_width / hframes)
		source_width = source_width / hframes
	if vframes > 1:
		source_height = source_height / vframes
	var source_rect := Rect2(
		frame_start_x,
		0,
		source_width,
		source_height,
	)
	var columns: int = int(max(1, int(ceil(source_rect.size.x / float(shard_size)))))
	var rows: int = int(max(1, int(ceil(source_rect.size.y / float(shard_size)))))
	var center_x := float(columns * shard_size) * 0.5
	var center_y := float(rows * shard_size) * 0.5
	for row_index in rows:
		for column_index in columns:
			var shard := Sprite2D.new()
			shard.texture = base_texture
			shard.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			shard.region_enabled = true
			shard.centered = false
			var rect_x: float = source_rect.position.x + column_index * shard_size
			var rect_y: float = source_rect.position.y + row_index * shard_size
			var rect_width: float = min(shard_size, source_rect.size.x - column_index * shard_size)
			var rect_height: float = min(shard_size, source_rect.size.y - row_index * shard_size)
			if rect_width <= 0 or rect_height <= 0:
				continue
			shard.region_rect = Rect2(rect_x, rect_y, rect_width, rect_height)
			shard.position = Vector2(
				column_index * shard_size - center_x + shard_size * 0.5,
				row_index * shard_size - center_y + shard_size * 0.5,
			)
			shard.rotation = randf_range(-PI * 0.75, PI * 0.75)
			shard.modulate = modulate
			burst_root.add_child(shard)
			var planet_center: Vector2 = container.get_parent().global_position
			var planet_inward: Vector2 = planet_center - global_position
			if planet_inward.length_squared() > 0.0:
				planet_inward = planet_inward.normalized()
			else:
				planet_inward = Vector2(0.0, 1.0)
			var planet_tangent: Vector2 = Vector2(-planet_inward.y, planet_inward.x)
			var drift_world: Vector2 = (
				planet_inward * randf_range(8.0, 20.0)
				+ planet_tangent * randf_range(-8.0, 8.0)
				+ Vector2(0.0, randf_range(2.0, 8.0))
			)
			var drift_local: Vector2 = burst_root.to_local(
				burst_root.to_global(shard.position) + drift_world
			) - shard.position
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(
				shard,
				"position",
				shard.position + drift_local,
				0.75,
			)
			tween.parallel().tween_property(
				shard,
				"rotation",
				shard.rotation + randf_range(-2.0, 2.0),
				0.75,
			)
			tween.parallel().tween_property(
				shard,
				"modulate:a",
				0.0,
				0.8,
			)
	var clear_tween := burst_root.create_tween()
	clear_tween.tween_interval(0.9)
	clear_tween.tween_callback(func() -> void:
		burst_root.queue_free())


func play_ambient_one_shot() -> void:
	pass


## 依据相对玩家角的可见性更新显示状态。
func update_visibility(player_angle: float) -> void:
	if is_consumed and kind == Kind.BAOBAB:
		visible = false
		return
	var relative_angle := angle_difference(player_angle, rotation)
	var is_on_facing_hemisphere := absf(relative_angle) <= WorldConstants.VISIBLE_HALF_ARC
	visible = is_on_facing_hemisphere
	if kind != Kind.KING:
		return
	if is_on_facing_hemisphere:
		return
	var signed_from_king := angle_difference(rotation, player_angle)
	flip_h = signed_from_king < 0.0
