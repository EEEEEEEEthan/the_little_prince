class_name Planet
extends Node2D
## 2D 圆弧星球：Body / Surface / Starfield 统一绕球心旋转，旋转角 = -player_angle。
## 小王子视觉上始终停在弧顶，实际由地表与星空反向旋转模拟行走。

@onready var body: Sprite2D = $Body
@onready var surface: Node2D = $Surface
@onready var starfield: Starfield = $Starfield

## 当前玩家角（弧顶处的地表角度），是旋转状态的唯一来源。
var player_angle: float = 0.0
## 玩家出生角（靠近玫瑰）。
var spawn_angle: float = WorldConstants.ROSE_ANGLE + WorldConstants.SPAWN_ANGLE_OFFSET
## 生成结果（供测试断言）。
var rose_angle: float = WorldConstants.ROSE_ANGLE
var volcano_angles: Array[float] = []
var baobab_angles: Array[float] = []
var surface_props: Array[SurfaceProp] = []

var _rng := RandomNumberGenerator.new()
var _occupied_angles: Array[float] = []

func _ready() -> void:
	_rng.seed = WorldConstants.WORLD_SEED
	_generate_surface()

func apex_global_position() -> Vector2:
	return global_position + Vector2(0.0, -WorldConstants.PLANET_RADIUS)

## 玩家沿线移动 direction 方向一段距离，驱动星球反向旋转。
func move_player(direction: float, delta: float) -> void:
	var angular_step := WorldConstants.PLAYER_SPEED / WorldConstants.PLANET_RADIUS * delta
	player_angle = fposmod(player_angle + direction * angular_step, TAU)
	_sync_rotation()

func teleport_player(angle: float) -> void:
	player_angle = fposmod(angle, TAU)
	_sync_rotation()

func _sync_rotation() -> void:
	var rotation_value := -player_angle
	body.rotation = rotation_value
	surface.rotation = rotation_value
	starfield.set_planet_rotation(rotation_value)
	for prop in surface_props:
		prop.update_visibility(player_angle)

func _generate_surface() -> void:
	_occupied_angles.clear()
	volcano_angles.clear()
	baobab_angles.clear()
	surface_props.clear()
	for child in surface.get_children():
		child.queue_free()

	_place_rose()
	_place_volcanoes()
	_place_baobabs()
	spawn_angle = fposmod(rose_angle + WorldConstants.SPAWN_ANGLE_OFFSET, TAU)

func _place_rose() -> void:
	rose_angle = WorldConstants.ROSE_ANGLE
	_occupied_angles.append(rose_angle)
	_spawn_prop(SurfaceProp.Kind.ROSE, rose_angle)

func _place_volcanoes() -> void:
	var base_angles: Array[float] = [TAU * 0.22, TAU * 0.55, TAU * 0.82]
	for index in WorldConstants.VOLCANO_COUNT:
		var angle := fposmod(
			base_angles[index % base_angles.size()] + _rng.randf_range(-0.08, 0.08), TAU
		)
		var attempts := 0
		while attempts < 200:
			attempts += 1
			var blocked := (
				_too_close_to_any(angle, _occupied_angles, WorldConstants.PROP_CLEARANCE)
				or _too_close_to_any(angle, volcano_angles, WorldConstants.VOLCANO_MIN_ANGLE)
			)
			if not blocked:
				break
			angle = _rng.randf() * TAU
		volcano_angles.append(angle)
		_occupied_angles.append(angle)
		_spawn_prop(SurfaceProp.Kind.VOLCANO, angle)

func _place_baobabs() -> void:
	var attempts := 0
	while baobab_angles.size() < WorldConstants.BAOBAB_COUNT and attempts < 8000:
		attempts += 1
		var angle := _rng.randf() * TAU
		if absf(angle_difference(angle, rose_angle)) < WorldConstants.PROP_CLEARANCE:
			continue
		if _too_close_to_any(angle, volcano_angles, WorldConstants.PROP_CLEARANCE):
			continue
		if _too_close_to_any(angle, baobab_angles, WorldConstants.BAOBAB_MIN_ANGLE):
			continue
		baobab_angles.append(angle)
		_occupied_angles.append(angle)
		_spawn_prop(SurfaceProp.Kind.BAOBAB, angle)

func _too_close_to_any(angle: float, others: Array[float], clearance: float) -> bool:
	for other in others:
		if absf(angle_difference(angle, other)) < clearance:
			return true
	return false

func _spawn_prop(kind: SurfaceProp.Kind, angle: float) -> void:
	var prop := SurfaceProp.new()
	surface.add_child(prop)
	prop.configure(kind, angle)
	surface_props.append(prop)
