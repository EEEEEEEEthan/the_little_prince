class_name DialogueBox
extends CanvasLayer
## 像素风打字机对话框：头像 + 说话人 + 逐字正文，出字时播放提示音。

const TYPEWRITER_INTERVAL := 0.045
const TYPEWRITER_FAST_INTERVAL := 0.012
const TYPEWRITER_VOLUME_DB := -8.0
const TYPEWRITER_FAST_VOLUME_DB := -20.0

@onready var _portrait: TextureRect = %Portrait
@onready var _speaker: Label = %Speaker
@onready var _body: Label = %Body
@onready var _typewriter: AudioStreamPlayer = $Typewriter
@onready var _timer: Timer = $Timer

var _lines: Array[DialogueLine] = []
var _index: int = 0
var _is_holding: bool = false
var _hold_started_while_typing: bool = false
var _blocked_joypad_devices: Dictionary = {}

func _ready() -> void:
	# tscn 保持可见便于编辑；开局再关。
	visible = false
	set_process(false)
	_timer.wait_time = TYPEWRITER_INTERVAL
	_timer.timeout.connect(_on_typewriter_tick)

func _process(_delta: float) -> void:
	for device: int in _blocked_joypad_devices.keys():
		if not _is_interact_joy_pressed_on(device):
			_blocked_joypad_devices.erase(device)
	var held := _is_interact_held()
	mark_holding(held)
	if is_typing():
		_set_accelerating(held)

func is_open() -> bool:
	return visible

func is_typing() -> bool:
	return not _timer.is_stopped()

func play(lines: Array[DialogueLine]) -> void:
	if lines.is_empty():
		close()
		return
	_lines = lines.duplicate()
	_index = 0
	_is_holding = false
	_hold_started_while_typing = false
	_blocked_joypad_devices.clear()
	for device in Input.get_connected_joypads():
		if _is_interact_joy_pressed_on(device):
			_blocked_joypad_devices[device] = true
	_set_accelerating(false)
	visible = true
	set_process(true)
	_show_line()
	mark_holding(_is_interact_held())

func mark_holding(held: bool) -> void:
	if not visible or held == _is_holding:
		return
	_is_holding = held
	if held:
		if is_typing():
			_hold_started_while_typing = true
			_set_accelerating(true)
		else:
			_hold_started_while_typing = false
		return
	if is_typing():
		_set_accelerating(false)
		return
	if _hold_started_while_typing:
		_hold_started_while_typing = false
		return
	_index += 1
	if _index >= _lines.size():
		close()
	else:
		_show_line()

func close() -> void:
	_timer.stop()
	_typewriter.stop()
	_is_holding = false
	_hold_started_while_typing = false
	_blocked_joypad_devices.clear()
	_set_accelerating(false)
	%ContinueTriangle.visible = false
	_lines.clear()
	_index = 0
	set_process(false)
	visible = false

func _show_line() -> void:
	var line := _lines[_index]
	_speaker.text = line.speaker
	_body.text = line.text
	_portrait.texture = line.portrait
	_body.visible_characters = 0
	%ContinueTriangle.visible = false
	_timer.start()
	_on_typewriter_tick()

func _set_accelerating(enabled: bool) -> void:
	var typewriter_wait_time := TYPEWRITER_FAST_INTERVAL if enabled else TYPEWRITER_INTERVAL
	var wait_time_changed := not is_equal_approx(_timer.wait_time, typewriter_wait_time)
	_timer.wait_time = typewriter_wait_time
	_typewriter.volume_db = TYPEWRITER_FAST_VOLUME_DB if enabled else TYPEWRITER_VOLUME_DB
	if wait_time_changed and not _timer.is_stopped():
		_timer.start()

func _is_interact_held() -> bool:
	for event in InputMap.action_get_events(&"interact"):
		var key := event as InputEventKey
		if key != null:
			if key.physical_keycode != KEY_NONE and Input.is_physical_key_pressed(key.physical_keycode):
				return true
			if key.keycode != KEY_NONE and Input.is_key_pressed(key.keycode):
				return true
			continue
		var joy := event as InputEventJoypadButton
		if joy == null:
			continue
		for device in Input.get_connected_joypads():
			if _blocked_joypad_devices.has(device):
				continue
			if Input.is_joy_button_pressed(device, joy.button_index):
				return true
	return DisplayServer.get_name() == "headless" and Input.is_action_pressed(&"interact")

func _is_interact_joy_pressed_on(device: int) -> bool:
	for event in InputMap.action_get_events(&"interact"):
		var joy := event as InputEventJoypadButton
		if joy != null and Input.is_joy_button_pressed(device, joy.button_index):
			return true
	return false

func _on_typewriter_tick() -> void:
	var total := _body.get_total_character_count()
	if _body.visible_characters < total:
		_body.visible_characters += 1
		_play_blip()
	if _body.visible_characters >= total:
		_timer.stop()
		_set_accelerating(false)
		%ContinueTriangle.visible = true

func _play_blip() -> void:
	var shown := _body.visible_characters
	if shown <= 0 or shown > _body.text.length():
		return
	var ch := _body.text[shown - 1]
	if ch == " " or ch == "\n" or ch == "　":
		return
	# headless 下 WAV playback 会在退出时泄漏，且没有实际输出
	if DisplayServer.get_name() == "headless":
		return
	_typewriter.stop()
	_typewriter.pitch_scale = randf_range(0.94, 1.08)
	_typewriter.play()
