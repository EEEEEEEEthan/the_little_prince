class_name Planet
extends Node2D
## 2D 圆弧星球：
##   Body / Surface / Starfield 同受 rotation = -player_angle（沙斑、岩边、地物与星空一起转）；
##   小王子视觉上始终停在弧顶（屏幕固定位置）。

@onready var body: PlanetBody = $Body
@onready var surface: Node2D = $Surface
@onready var starfield: Starfield = $Starfield

## 当前玩家角（由 Player 改角后立刻写入，同帧一致）
var player_angle: float = 0.0
## 实际半径（内部 256×224 下通常等于常量）
var planet_radius: float = WorldConstants.PLANET_RADIUS

## 生成结果（供测试断言）
var volcano_angles: Array[float] = []
var baobab_angles: Array[float] = []
var rose_angle: float = WorldConstants.ROSE_ANGLE
var spawn_angle: float = WorldConstants.ROSE_ANGLE + WorldConstants.SPAWN_ANGLE_OFFSET
var surface_props: Array[SurfaceProp] = []

var _rng := RandomNumberGenerator.new()
var _occupied_angles: Array[float] = []

func _ready() -> void:
	_rng.seed = WorldConstants.WORLD_SEED
	if body != null:
		body.set_radius(planet_radius)
	_generate_surface()
	_apply_radius(planet_radius)

## 由 Main 调用：更新球心位置与半径（内部视口固定后半径通常不变）
func apply_layout(center: Vector2, radius: float) -> void:
	global_position = center
	_apply_radius(radius)

func _apply_radius(radius: float) -> void:
	planet_radius = radius
	if body != null:
		body.set_radius(radius)
	for prop in surface_props:
		prop.set_planet_radius(radius)
	_sync_planet_rotation()

## 弧顶世界坐标（小王子脚底应踩的位置）
func apex_global_position() -> Vector2:
	return global_position + Vector2(0, -planet_radius)

## 相对基准半径的视觉缩放（地物 / 玩家共用）
func visual_scale() -> float:
	return planet_radius / WorldConstants.PLANET_RADIUS

## 同步星球旋转与地物可见性（Body + Surface 同角）
func set_player_angle(angle: float) -> void:
	player_angle = angle
	_sync_planet_rotation()

func _sync_planet_rotation() -> void:
	var rot: float = -player_angle
	if body != null:
		body.rotation = rot
	if surface != null:
		surface.rotation = rot
	if starfield != null:
		starfield.set_planet_rotation(rot)
	for prop in surface_props:
		prop.update_visibility(player_angle)

## ---------- 地物生成 ----------

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
	# 均匀三分点附近抖动，保证角间距足够大
	var base: Array[float] = [
		TAU * 0.22,
		TAU * 0.55,
		TAU * 0.82,
	]
	for i in WorldConstants.VOLCANO_COUNT:
		var a: float = base[i % base.size()]
		a = fposmod(a + _rng.randf_range(-0.08, 0.08), TAU)
		var ok := false
		var attempts := 0
		while attempts < 200:
			attempts += 1
			ok = _angle_free(a, WorldConstants.PROP_CLEARANCE)
			for other in volcano_angles:
				if _angular_distance(a, other) < WorldConstants.VOLCANO_MIN_ANGLE:
					ok = false
					break
			if ok:
				break
			a = _rng.randf() * TAU
		volcano_angles.append(a)
		_occupied_angles.append(a)
		_spawn_prop(SurfaceProp.Kind.VOLCANO, a)

func _place_baobabs() -> void:
	var attempts := 0
	while baobab_angles.size() < WorldConstants.BAOBAB_COUNT and attempts < 8000:
		attempts += 1
		var a: float = _rng.randf() * TAU
		# 相对玫瑰/火山用 PROP_CLEARANCE；树彼此用更紧的 BAOBAB_MIN_ANGLE
		if _angular_distance(a, rose_angle) < WorldConstants.PROP_CLEARANCE:
			continue
		var blocked := false
		for v in volcano_angles:
			if _angular_distance(a, v) < WorldConstants.PROP_CLEARANCE:
				blocked = true
				break
		if blocked:
			continue
		for other in baobab_angles:
			if _angular_distance(a, other) < WorldConstants.BAOBAB_MIN_ANGLE:
				blocked = true
				break
		if blocked:
			continue
		baobab_angles.append(a)
		_occupied_angles.append(a)
		_spawn_prop(SurfaceProp.Kind.BAOBAB, a)

func _spawn_prop(kind: SurfaceProp.Kind, angle: float) -> SurfaceProp:
	var prop := SurfaceProp.new()
	surface.add_child(prop)
	prop.configure(kind, angle, planet_radius)
	surface_props.append(prop)
	return prop

func _angle_free(a: float, clearance: float) -> bool:
	for other in _occupied_angles:
		if _angular_distance(a, other) < clearance:
			return false
	return true

static func _angular_distance(a: float, b: float) -> float:
	return absf(angle_difference(a, b))
