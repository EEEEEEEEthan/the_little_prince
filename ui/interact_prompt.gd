class_name InteractPrompt
extends Sprite2D
## 手柄 A 键提示：挂到当前可互动物体头顶，轻微上下浮动。

var _home: Node

func _ready() -> void:
	_home = get_parent()
	visible = false
	set_process(false)

func show_on(prop: SurfaceProp) -> void:
	reparent(prop)
	position = Vector2(0.0, WorldConstants.INTERACT_PROMPT_LOCAL_Y)
	rotation = 0.0
	offset = Vector2.ZERO
	visible = true
	set_process(true)

func hide_prompt() -> void:
	visible = false
	set_process(false)
	offset = Vector2.ZERO
	if _home != null and get_parent() != _home:
		reparent(_home)

func _process(_delta: float) -> void:
	offset = Vector2(0.0, sin(Time.get_ticks_msec() * 0.006) * 1.5)
