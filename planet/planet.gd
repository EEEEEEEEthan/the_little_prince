class_name Planet
extends Node2D
## 2D 圆弧星球：Body / Surface / Sky 统一绕球心旋转，旋转角 = -player_angle。
## 地表地物静态写在 planet.tscn；_ready 时按 PLANET_RADIUS 径向贴地。
## Body 贴图按显示直径原尺寸绘制，不使用 scale。
## 小王子视觉上始终停在弧顶，实际由地表与星空反向旋转模拟行走。

@onready var body: Sprite2D = $Body
@onready var surface: Node2D = $Surface
@onready var sky = $Sky

## 当前玩家角（弧顶处的地表角度），是旋转状态的唯一来源。
var player_angle: float = 0.0
## 玩家出生角（靠近玫瑰）。
var spawn_angle: float = 0.0
## 地表地物数据（静态场景内收集，供测试断言）。
var rose_angle: float = 0.0
var volcano_angles: Array[float] = []
var baobab_angles: Array[float] = []
var surface_props: Array[SurfaceProp] = []

## 当前角速度（弧度/秒），经阻尼向目标速度平滑逼近。
var _angular_velocity: float = 0.0

func _ready() -> void:
	# 星球贴图按显示直径原尺寸绘制，禁止用 scale 放大。
	body.scale = Vector2.ONE
	_collect_surface_props()
	_snap_surface_props_to_radius()

func _collect_surface_props() -> void:
	for child in surface.get_children():
		var prop := child as SurfaceProp
		surface_props.append(prop)
		match prop.kind:
			SurfaceProp.Kind.ROSE:
				rose_angle = prop.rotation
			SurfaceProp.Kind.VOLCANO:
				volcano_angles.append(prop.rotation)
			SurfaceProp.Kind.BAOBAB:
				baobab_angles.append(prop.rotation)
	spawn_angle = fposmod(rose_angle + WorldConstants.SPAWN_ANGLE_OFFSET, TAU)

func apex_global_position() -> Vector2:
	return global_position + Vector2(0.0, -WorldConstants.PLANET_RADIUS)

func is_moving() -> bool:
	return absf(_angular_velocity) > 0.02

## 半径放大后地物仍按旧圆摆放时，沿径向推到当前星球表面。
func _snap_surface_props_to_radius() -> void:
	var radius := WorldConstants.PLANET_RADIUS
	for prop in surface_props:
		var length := prop.position.length()
		if length <= 0.001:
			prop.position = Vector2(0.0, -radius)
		else:
			prop.position *= radius / length

## 玩家沿线移动 direction 方向，角速度带阻尼平滑逼近目标，驱动星球反向旋转。
func move_player(direction: float, delta: float) -> void:
	var max_angular_speed := WorldConstants.PLAYER_SPEED / WorldConstants.PLANET_RADIUS
	var target_velocity := direction * max_angular_speed
	var smoothing := 1.0 - exp(-WorldConstants.PLAYER_DAMPING * delta)
	_angular_velocity = lerp(_angular_velocity, target_velocity, smoothing)
	player_angle = fposmod(player_angle + _angular_velocity * delta, TAU)
	_sync_rotation()

func teleport_player(angle: float) -> void:
	_angular_velocity = 0.0
	player_angle = fposmod(angle, TAU)
	_sync_rotation()

func _sync_rotation() -> void:
	var rotation_value := -player_angle
	body.rotation = rotation_value
	surface.rotation = rotation_value
	sky.set_planet_rotation(rotation_value)
	for prop in surface_props:
		prop.update_visibility(player_angle)
