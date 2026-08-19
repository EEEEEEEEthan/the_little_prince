class_name DialogueBox
extends CanvasLayer
## 像素风打字机对话框：头像 + 说话人 + 逐字正文，出字时播放提示音。

const TYPEWRITER_INTERVAL := 0.045

@onready var _portrait: TextureRect = %Portrait
@onready var _speaker: Label = %Speaker
@onready var _body: Label = %Body
@onready var _typewriter: AudioStreamPlayer = $Typewriter
@onready var _timer: Timer = $Timer

var _lines: Array[DialogueLine] = []
var _index: int = 0

func _ready() -> void:
	visible = false
	_timer.wait_time = TYPEWRITER_INTERVAL
	_timer.timeout.connect(_on_typewriter_tick)

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
	visible = true
	_show_line()

func advance() -> void:
	if not visible:
		return
	if is_typing():
		_finish_line()
		return
	_index += 1
	if _index >= _lines.size():
		close()
	else:
		_show_line()

func close() -> void:
	_timer.stop()
	_typewriter.stop()
	_lines.clear()
	_index = 0
	visible = false

func _show_line() -> void:
	var line := _lines[_index]
	_speaker.text = line.speaker
	_body.text = line.text
	_portrait.texture = line.portrait
	_body.visible_characters = 0
	_timer.start()
	_on_typewriter_tick()

func _finish_line() -> void:
	_timer.stop()
	_typewriter.stop()
	_body.visible_characters = -1

func _on_typewriter_tick() -> void:
	var total := _body.get_total_character_count()
	if _body.visible_characters < 0 or _body.visible_characters >= total:
		_timer.stop()
		return
	_body.visible_characters += 1
	_play_blip()
	if _body.visible_characters >= total:
		_timer.stop()

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
