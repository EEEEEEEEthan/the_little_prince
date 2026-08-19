class_name Player
extends Sprite2D
## 小王子：左右输入驱动星球旋转，自身钉在弧顶。
## 角度状态由 Planet 持有，Player 仅把输入意图转发过去。

@onready var planet: Planet = %Planet
@onready var interaction: Interaction = %Interaction

func _ready() -> void:
	offset = Vector2(0.0, -float(texture.get_height()) * 0.5)

func _physics_process(delta: float) -> void:
	var direction := 0.0
	if not interaction.is_busy():
		direction = Input.get_axis("move_left", "move_right")
	planet.move_player(direction, delta)
