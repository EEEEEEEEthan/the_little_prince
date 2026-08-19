class_name Interaction
extends Node
## 靠近可互动物体时显示 A 提示；按 interact（键盘 Submit / 手柄 A）打开对话框。

@onready var planet: Planet = %Planet
@onready var dialogue: DialogueBox = %DialogueBox
@onready var prompt: InteractPrompt = %InteractPrompt

var _focus: SurfaceProp

func is_busy() -> bool:
	return dialogue.is_open()

func _process(_delta: float) -> void:
	if is_busy():
		_set_focus(null)
		return
	if Input.is_action_just_pressed(&"interact"):
		_on_interact()
	_set_focus(planet.find_nearest_interactable())

func _on_interact() -> void:
	if _focus == null:
		return
	var lines := DialogueCatalog.lines_for_id(_focus.get_dialogue_id())
	if lines.is_empty():
		return
	dialogue.play(lines)
	if dialogue.is_open():
		dialogue.mark_holding(true)
	_set_focus(null)

func _set_focus(prop: SurfaceProp) -> void:
	if prop == _focus:
		return
	_focus = prop
	if _focus == null:
		prompt.hide_prompt()
	else:
		prompt.show_on(_focus)
