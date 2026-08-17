extends Node2D
## 全局总控（真正的 2D 圆弧星球）：
##   Main
##   ├── Starfield —— 深空 + 星点
##   ├── Planet    —— Body + Surface 同受 -player_angle
##   └── Player    —— 改角后立刻通知 Planet；始终钉在弧顶
##
## 力学：角速度 = PLAYER_SPEED / planet_radius；
## Body/Surface.rotation = -player_angle，玩家屏幕位置固定在弧顶。

@onready var starfield: Starfield = $Starfield
@onready var planet: Planet = $Planet
@onready var player: Player = $Player

func _ready() -> void:
	InputSetup.ensure_move_actions()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	player.planet = planet
	_layout_world()
	# 出生角靠近玫瑰；set_angle_and_sync 同帧驱动 Body/Surface
	player.set_angle_and_sync(planet.spawn_angle)

func _on_viewport_size_changed() -> void:
	_layout_world()
	player.place_at_apex(planet.apex_global_position())

## 按窗口重算：小半径 + 高 APEX_Y_RATIO → 球心更靠下，底部只露浅弧
func _layout_world() -> void:
	var size: Vector2 = get_viewport_rect().size
	if size.x < 1.0 or size.y < 1.0:
		size = Vector2(WorldConstants.REFERENCE_VIEWPORT, WorldConstants.REFERENCE_VIEWPORT)

	starfield.set_viewport_size(size)

	var scale: float = minf(size.x, size.y) / WorldConstants.REFERENCE_VIEWPORT
	var radius: float = WorldConstants.PLANET_RADIUS * scale
	var apex_y: float = size.y * WorldConstants.APEX_Y_RATIO
	# 弧顶在 apex_y，球心在其正下方 radius 处（通常已落在屏幕底边之外）
	var center := Vector2(size.x * 0.5, apex_y + radius)

	planet.apply_layout(center, radius)
	player.set_planet_radius(radius)
