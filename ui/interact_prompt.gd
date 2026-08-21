class_name InteractPrompt
extends Sprite2D
## 手柄 A 键提示：跟随目标头顶移动，自身保持屏幕朝向，不继承星球旋转。
## 长按交互时按钮本身按填充比例做进度渲染。

var hold_fill_ratio: float = 0.0:
	set(value):
		hold_fill_ratio = clampf(value, 0.0, 1.0)
		if not is_node_ready():
			await ready
		(material as ShaderMaterial).set_shader_parameter(&"fill_ratio", hold_fill_ratio)

var _target: SurfaceProp


func _ready() -> void:
	# tscn 保持可见便于编辑；开局再关。
	visible = false
	set_process(false)


func show_on(prop: SurfaceProp) -> void:
	_target = prop
	rotation = 0.0
	offset = Vector2.ZERO
	hold_fill_ratio = 0.0
	visible = true
	set_process(true)
	_sync_to_target()


func hide_prompt() -> void:
	_target = null
	hold_fill_ratio = 0.0
	visible = false
	set_process(false)
	offset = Vector2.ZERO


func _process(_delta: float) -> void:
	_sync_to_target()
	if not visible:
		return
	if hold_fill_ratio > 0.0:
		offset = Vector2.ZERO
		return
	offset = Vector2(0.0, sin(Time.get_ticks_msec() * 0.006) * 1.5)


func _sync_to_target() -> void:
	if _target == null or not is_instance_valid(_target):
		hide_prompt()
		return
	global_position = _target.to_global(Vector2(0.0, WorldConstants.INTERACT_PROMPT_LOCAL_Y))
	global_rotation = 0.0
