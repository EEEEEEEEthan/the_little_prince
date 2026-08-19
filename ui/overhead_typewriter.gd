class_name OverheadTypewriter
extends Node2D
## 弧顶头顶打字机：纯白居中逐字出现，停留后渐隐。

const TYPEWRITER_INTERVAL := 0.08
const HOLD_DURATION_SECONDS := 1.6
const FADE_DURATION_SECONDS := 0.9
const AMBIENT_START_DELAY_SECONDS := 1.2
const AMBIENT_GAP_SECONDS := 1.6
const TYPEWRITER_VOLUME_DB := -14.0

const AMBIENT_LINES: PackedStringArray = [
	"风从沙上走过。",
	"很轻。",
	"天，低了一点。",
	"有一颗星，没有眨眼。",
]

@export var play_on_ready: bool = true

var _play_generation: int = 0
var _fade_tween: Tween


func _ready() -> void:
	visible = false
	global_position = _head_global_position()
	%Typewriter.volume_db = TYPEWRITER_VOLUME_DB
	if play_on_ready:
		_play_ambient_loop()


func play(display_text: String) -> void:
	_play_generation += 1
	var play_generation := _play_generation
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null
	if display_text.is_empty():
		visible = false
		modulate = Color.WHITE
		return
	global_position = _head_global_position()
	modulate = Color.WHITE
	var body := %Body
	var typewriter := %Typewriter
	var skip_blip := DisplayServer.get_name() == "headless"
	body.text = display_text
	body.visible_characters = 0
	visible = true
	var play_blip := func() -> void:
		var shown: int = body.visible_characters
		if skip_blip or shown <= 0 or shown > body.text.length():
			return
		var character: String = body.text[shown - 1]
		if character == " " or character == "\n" or character == "　":
			return
		typewriter.stop()
		typewriter.pitch_scale = randf_range(0.94, 1.08)
		typewriter.play()
	var total_characters := display_text.length()
	while body.visible_characters < total_characters:
		body.visible_characters += 1
		play_blip.call()
		if body.visible_characters >= total_characters:
			break
		await get_tree().create_timer(TYPEWRITER_INTERVAL).timeout
		if play_generation != _play_generation or not is_inside_tree():
			return
	await get_tree().create_timer(HOLD_DURATION_SECONDS).timeout
	if play_generation != _play_generation or not is_inside_tree():
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION_SECONDS)
	await get_tree().create_timer(FADE_DURATION_SECONDS).timeout
	if play_generation != _play_generation or not is_inside_tree():
		return
	visible = false
	modulate = Color.WHITE
	_fade_tween = null


func _play_ambient_loop() -> void:
	await get_tree().create_timer(AMBIENT_START_DELAY_SECONDS).timeout
	while is_inside_tree() and play_on_ready:
		for line in AMBIENT_LINES:
			if not play_on_ready or not is_inside_tree():
				return
			await play(line)
			await get_tree().create_timer(AMBIENT_GAP_SECONDS).timeout


func _head_global_position() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
			viewport_size.x * 0.5,
			viewport_size.y * WorldConstants.APEX_Y_RATIO
			+ WorldConstants.OVERHEAD_TYPEWRITER_LOCAL_Y,
	).round()
