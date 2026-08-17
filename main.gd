extends Control
## 入口总控：把星球与玩家按固定 256×224 视口布局并开局。
## 视口拉伸、像素过滤等静态配置均已写在 main.tscn。

@onready var game_viewport: SubViewport = $GameView/GameViewport
@onready var planet: Planet = $GameView/GameViewport/Planet
@onready var player: Player = $GameView/GameViewport/Player

func _ready() -> void:
	_layout_world()
	planet.teleport_player(planet.spawn_angle)

func _layout_world() -> void:
	var viewport_size := Vector2(game_viewport.size)
	var apex_y := viewport_size.y * WorldConstants.APEX_Y_RATIO
	planet.global_position = Vector2(
		viewport_size.x * 0.5, apex_y + WorldConstants.PLANET_RADIUS
	)
	player.global_position = planet.apex_global_position()
