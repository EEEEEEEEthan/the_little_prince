class_name Interaction
extends Node
## 靠近可互动物体时显示 A 提示；点按或长按 interact（键盘 Submit / 手柄 A）交互。

@onready var planet: Planet = %Planet
@onready var player: Player = %Player
@onready var dialogue: DialogueBox = %DialogueBox
@onready var prompt: InteractPrompt = %InteractPrompt
@onready var story: B612Story = %B612Story

var _focus: SurfaceProp
var _hold_elapsed_seconds: float = 0.0


func is_busy() -> bool:
	return dialogue.is_open() or story.is_blocking_input or _hold_elapsed_seconds > 0.0


func _process(delta: float) -> void:
	if dialogue.is_open() or story.is_blocking_input:
		_set_focus(null)
		return
	if story.is_active:
		_set_focus(planet.find_nearest_interactable(story.accepts_interact))
	else:
		_set_focus(planet.find_nearest_interactable())
	if _focus == null:
		_clear_hold()
		return
	var required_hold_seconds := story.interact_hold_seconds(_focus)
	if required_hold_seconds > 0.0:
		if Input.is_action_pressed(&"interact"):
			if _hold_elapsed_seconds <= 0.0:
				planet.angular_velocity = 0.0
			_hold_elapsed_seconds += delta
			prompt.hold_fill_ratio = _hold_elapsed_seconds / required_hold_seconds
			if _hold_elapsed_seconds >= required_hold_seconds:
				_clear_hold()
				_on_interact()
		else:
			_clear_hold()
		return
	_clear_hold()
	if Input.is_action_just_pressed(&"interact"):
		_on_interact()


func _on_interact() -> void:
	if _focus == null:
		return
	if story.try_handle_interact(_focus):
		_set_focus(null)
		return
	var lines := DialogueCatalog.lines_for_id(_focus.get_dialogue_id())
	if lines.is_empty():
		return
	dialogue.play(lines, player, _focus)
	if dialogue.is_open() and Input.is_action_pressed(&"interact"):
		dialogue.mark_holding(true)
	_set_focus(null)


func _set_focus(prop: SurfaceProp) -> void:
	if prop == _focus:
		return
	_clear_hold()
	_focus = prop
	if _focus == null:
		prompt.hide_prompt()
	else:
		prompt.show_on(_focus)


func _clear_hold() -> void:
	if _hold_elapsed_seconds == 0.0 and is_zero_approx(prompt.hold_fill_ratio):
		return
	_hold_elapsed_seconds = 0.0
	prompt.hold_fill_ratio = 0.0
