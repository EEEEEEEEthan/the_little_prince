class_name Player
extends Sprite2D
## 小王子：左右输入驱动星球旋转，自身钉在弧顶。
## 贴图为 idle+walk 横拼 spritesheet，按角速度切帧；左右用 flip_h。

@onready var planet: Planet = %Planet

var _anim_time: float = 0.0
var _was_moving: bool = false

func _ready() -> void:
	hframes = WorldConstants.PLAYER_SPRITE_FRAME_COUNT
	vframes = 1
	scale = Vector2.ONE
	offset = Vector2(0.0, -float(WorldConstants.PLAYER_SPRITE_HEIGHT) * 0.5)
	frame = 0

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	planet.move_player(direction, delta)
	_update_animation(direction, delta)

func _update_animation(direction: float, delta: float) -> void:
	if absf(direction) > 0.01:
		flip_h = direction < 0.0
	var moving := planet.is_moving()
	if moving != _was_moving:
		_anim_time = 0.0
		_was_moving = moving
	_anim_time += delta
	if moving:
		var walk_count := WorldConstants.PLAYER_WALK_FRAME_COUNT
		var idx := int(_anim_time * WorldConstants.PLAYER_WALK_FPS) % walk_count
		frame = WorldConstants.PLAYER_IDLE_FRAME_COUNT + idx
	else:
		var idle_count := WorldConstants.PLAYER_IDLE_FRAME_COUNT
		var idx := int(_anim_time * WorldConstants.PLAYER_IDLE_FPS) % idle_count
		frame = idx
