extends Control
## 入口总控：把星球与玩家按固定 256×224 视口布局并开局。
## 视口拉伸、像素过滤等静态配置均已写在 main.tscn。

@onready var game_viewport: SubViewport = $GameView/GameViewport
@onready var planet: Planet = $GameView/GameViewport/Planet
@onready var player: Player = $GameView/GameViewport/Player
@onready var dialogue: DialogueBox = %DialogueBox

func _ready() -> void:
	_layout_world()
	planet.teleport_player(planet.spawn_angle)

func _input(event: InputEvent) -> void:
	if not dialogue.is_open() or event.is_echo() or not event.is_action(&"interact"):
		return
	dialogue.mark_holding(event.is_pressed())

func _layout_world() -> void:
	var viewport_size := Vector2(game_viewport.size)
	var apex_y := viewport_size.y * WorldConstants.APEX_Y_RATIO
	planet.global_position = Vector2(
		viewport_size.x * 0.5, apex_y + WorldConstants.PLANET_RADIUS
	)
	player.global_position = planet.apex_global_position()
