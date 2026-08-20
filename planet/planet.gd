class_name Planet
extends Node2D
## 可复用 2D 圆弧星球：Body / Surface / Sky / Clouds 统一绕球心旋转。
## 用法：改半径、贴图、自转等参数；树 / 玫瑰等地表物件拖到 Surface 下即可。
## Body 贴图按显示直径原尺寸绘制，不使用 scale。
## 小王子视觉上始终停在弧顶，实际由地表与星空反向旋转模拟行走。

@export var radius: float = WorldConstants.PLANET_RADIUS:
	set(value):
		radius = value

@export var body_texture: Texture2D:
	set(value):
		body_texture = value
		if not is_node_ready():
			await ready
		%Body.texture = body_texture

@export var starfield_texture: Texture2D:
	set(value):
		starfield_texture = value
		if not is_node_ready():
			await ready
		%Sky.texture = starfield_texture

@export var star_rotation_speed: float = WorldConstants.STAR_ROTATION_SPEED:
	set(value):
		star_rotation_speed = value
		if not is_node_ready():
			await ready
		%Sky.star_rotation_speed = star_rotation_speed

@export var cloud_texture: Texture2D:
	set(value):
		cloud_texture = value
		if not is_node_ready():
			await ready
		%CloudSprites.texture = cloud_texture

@export var cloud_drift_speed: float = WorldConstants.CLOUD_DRIFT_SPEED:
	set(value):
		cloud_drift_speed = value
		if not is_node_ready():
			await ready
		%Clouds.drift_speed = cloud_drift_speed

@export var cloud_orbit_min_radius: float = WorldConstants.CLOUD_ORBIT_MIN_RADIUS:
	set(value):
		cloud_orbit_min_radius = value
		if not is_node_ready():
			await ready
		_apply_cloud_orbits()

@export var cloud_orbit_max_radius: float = WorldConstants.CLOUD_ORBIT_MAX_RADIUS:
	set(value):
		cloud_orbit_max_radius = value
		if not is_node_ready():
			await ready
		_apply_cloud_orbits()

## 当前玩家角（弧顶处的地表角度），是旋转状态的唯一来源。
var player_angle: float = 0.0
## 玩家出生角（靠近玫瑰）。
var spawn_angle: float = 0.0
## 地表地物数据（静态场景内收集，供测试断言）。
var rose_angle: float = 0.0
var volcano_angles: Array[float] = []
var baobab_angles: Array[float] = []
var surface_props: Array[SurfaceProp] = []

## 当前角速度（弧度/秒），经阻尼向目标速度平滑逼近。正值表示向右走。
var angular_velocity: float = 0.0

@onready var body: Sprite2D = %Body
@onready var surface: Node2D = %Surface
@onready var sky = %Sky
@onready var clouds = %Clouds


func _ready() -> void:
	# 星球贴图按显示直径原尺寸绘制，禁止用 scale 放大。
	body.scale = Vector2.ONE
	_collect_surface_props()


func _collect_surface_props() -> void:
	for child in surface.get_children():
		var prop := child as SurfaceProp
		if prop == null:
			continue
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
	return global_position + Vector2(0.0, -radius)


func is_moving() -> bool:
	return absf(angular_velocity) > 0.02


## 玩家沿线移动 direction 方向，角速度带阻尼平滑逼近目标，驱动星球反向旋转。
func move_player(direction: float, delta: float) -> void:
	var max_angular_speed := WorldConstants.PLAYER_SPEED / radius
	var target_velocity := direction * max_angular_speed
	var smoothing := 1.0 - exp(-WorldConstants.PLAYER_DAMPING * delta)
	angular_velocity = lerp(angular_velocity, target_velocity, smoothing)
	player_angle = fposmod(player_angle + angular_velocity * delta, TAU)
	_sync_rotation()


## 弧顶附近最近的可互动物体；超出 INTERACT_RANGE_PX 则返回 null。
func find_nearest_interactable() -> SurfaceProp:
	var max_arc := WorldConstants.INTERACT_RANGE_PX / radius
	var best: SurfaceProp = null
	var best_diff := max_arc
	for prop in surface_props:
		if not prop.is_interactable():
			continue
		var diff := absf(angle_difference(player_angle, prop.rotation))
		if diff <= best_diff:
			best_diff = diff
			best = prop
	return best


func teleport_player(angle: float) -> void:
	angular_velocity = 0.0
	player_angle = fposmod(angle, TAU)
	_sync_rotation()


func _sync_rotation() -> void:
	var rotation_value := -player_angle
	body.rotation = rotation_value
	surface.rotation = rotation_value
	sky.set_planet_rotation(rotation_value)
	clouds.set_planet_rotation(rotation_value)
	for prop in surface_props:
		prop.update_visibility(player_angle)


func _apply_cloud_orbits() -> void:
	%Clouds.orbit_min_radius = cloud_orbit_min_radius
	%Clouds.orbit_max_radius = cloud_orbit_max_radius
	%Clouds.rebuild_instances()
