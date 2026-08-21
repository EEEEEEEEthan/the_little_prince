class_name DialogueBox
extends CanvasLayer
## 像素风打字机对话框：说话人头像跟站位左右，逐字正文。

signal closed
signal line_advanced

const TYPEWRITER_INTERVAL := 0.045
const TYPEWRITER_FAST_INTERVAL := 0.012
const TYPEWRITER_VOLUME_DB := -8.0
const TYPEWRITER_FAST_VOLUME_DB := -20.0

@onready var _body: Label = %Body
@onready var _typewriter: AudioStreamPlayer = $Typewriter
@onready var _timer: Timer = $Timer

var _lines: Array[DialogueLine] = []
var _index: int = 0
var _is_holding: bool = false
var _advance_on_confirm_release: bool = false
var _saw_confirm_released_while_idle: bool = false
var _is_revealing: bool = false
var _typewriter_accum_seconds: float = 0.0
var _close_after_last: bool = true
var _prince_stands_on_left: bool = true


func _ready() -> void:
	# tscn 保持可见便于编辑；开局再关。
	visible = false
	set_process(false)
	_timer.wait_time = TYPEWRITER_INTERVAL


func _process(delta: float) -> void:
	if visible and not _is_revealing and not _is_holding:
		_saw_confirm_released_while_idle = true
	if not _is_revealing:
		return
	var typewriter_interval := (
		TYPEWRITER_FAST_INTERVAL if _is_holding else TYPEWRITER_INTERVAL
	)
	_typewriter_accum_seconds += delta
	while _is_revealing and _typewriter_accum_seconds >= typewriter_interval:
		_typewriter_accum_seconds -= typewriter_interval
		_reveal_next_character()


func is_open() -> bool:
	return visible


func is_typing() -> bool:
	return _is_revealing


func play(
		lines: Array[DialogueLine],
		prince: Node2D = null,
		partner: SurfaceProp = null,
) -> void:
	_play_lines(lines, true, prince, partner)


func play_line(
		line: DialogueLine,
		prince: Node2D = null,
		partner: SurfaceProp = null,
) -> void:
	var lines: Array[DialogueLine] = []
	lines.append(line)
	_play_lines(lines, false, prince, partner)


func mark_holding(held: bool) -> void:
	if not visible or held == _is_holding:
		return
	_is_holding = held
	if held:
		if _index >= _lines.size() - 1 and _saw_confirm_released_while_idle:
			_finish_current_line()
			return
		_advance_on_confirm_release = not is_typing() and _saw_confirm_released_while_idle
		if is_typing():
			_set_accelerating(true)
		return
	if is_typing():
		_set_accelerating(false)
		return
	if not _advance_on_confirm_release:
		return
	_advance_on_confirm_release = false
	_index += 1
	if _index >= _lines.size():
		_finish_current_line()
	else:
		_show_line()


func close() -> void:
	var was_open := visible
	var should_advance_line := was_open and not _close_after_last
	_timer.stop()
	_typewriter.stop()
	_is_holding = false
	_advance_on_confirm_release = false
	_saw_confirm_released_while_idle = false
	_is_revealing = false
	_typewriter_accum_seconds = 0.0
	_set_accelerating(false)
	%ContinueTriangle.visible = false
	_lines.clear()
	_index = 0
	set_process(false)
	visible = false
	if should_advance_line:
		line_advanced.emit()
	if was_open:
		closed.emit()


func _play_lines(
		lines: Array[DialogueLine],
		close_after_last: bool,
		prince: Node2D,
		partner: SurfaceProp,
) -> void:
	if lines.is_empty():
		close()
		return
	_close_after_last = close_after_last
	_prince_stands_on_left = (
			prince == null
			or partner == null
			or prince.global_position.x <= partner.global_position.x
	)
	_lines = lines.duplicate()
	_index = 0
	_is_holding = false
	_advance_on_confirm_release = false
	_saw_confirm_released_while_idle = false
	_set_accelerating(false)
	visible = true
	set_process(true)
	_show_line()


func _finish_current_line() -> void:
	if _close_after_last:
		close()
		return
	line_advanced.emit()


func _show_line() -> void:
	var line := _lines[_index]
	var prince_is_speaking := line.speaker == DialogueCatalog.PRINCE_SPEAKER
	var portrait_on_left := prince_is_speaking == _prince_stands_on_left
	%Portrait.texture = line.portrait
	%ContentRow.move_child(%Portrait, 0 if portrait_on_left else 1)
	%Speaker.text = line.speaker
	%Speaker.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT if portrait_on_left
			else HORIZONTAL_ALIGNMENT_RIGHT
	)
	_body.text = line.text
	_body.visible_characters = 0
	%ContinueTriangle.visible = false
	_timer.stop()
	_is_revealing = true
	_typewriter_accum_seconds = 0.0
	_reveal_next_character()


func _set_accelerating(enabled: bool) -> void:
	_timer.wait_time = TYPEWRITER_FAST_INTERVAL if enabled else TYPEWRITER_INTERVAL
	_typewriter.volume_db = TYPEWRITER_FAST_VOLUME_DB if enabled else TYPEWRITER_VOLUME_DB


func _reveal_next_character() -> void:
	var total := _body.get_total_character_count()
	if _body.visible_characters < total:
		_body.visible_characters += 1
		_play_blip()
	if _body.visible_characters >= total:
		_is_revealing = false
		_typewriter_accum_seconds = 0.0
		_set_accelerating(false)
		%ContinueTriangle.visible = true
		if _is_holding:
			_advance_on_confirm_release = false
			_saw_confirm_released_while_idle = false


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
