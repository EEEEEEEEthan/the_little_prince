class_name B612Story
extends Node
## B612 故乡剧情：开场对白 → 罩玻璃罩 → 拔苗 → 告别 → 离星。
## 第一次跨入日落时播头顶叙事，不作为关卡。

enum Beat {
	OPENING,
	COVER_ROSE,
	PULL_SHOOTS,
	FAREWELL,
	DEPART,
}

const SHOOT_DIALOGUE_ID := &"baobab_shoot"
const SHOOT_COUNT := WorldConstants.BAOBAB_COUNT
const DEPART_LIFT_PIXELS := 72.0
const DEPART_LIFT_SECONDS := 2.4
const FADE_TO_BLACK_SECONDS := 1.2
const OPENING_MOVE_SPEED_SCALE := 0.8
const OPENING_OVERHEAD_START_DELAY_SECONDS := 3.0
const SUNSET_CINEMATIC_PRE_LIFT_DELAY_SECONDS := 0.3
const SUNSET_CAMERA_LIFT_SECONDS := 1.0
const SUNSET_CAMERA_LIFT_PIXELS := 16.0
const SUNSET_CINEMATIC_POST_NARRATION_DELAY_SECONDS := 0.5

@export var auto_start: bool = true

var skip_cinematics: bool = false
var is_active: bool = false
var is_blocking_input: bool = false
var beat: Beat = Beat.OPENING
var pulled_shoot_count: int = 0
var _last_sky_phase: float = SkyPhase.NOON_PHASE
var _has_played_first_sunset_narration: bool = false
var _is_first_sunset_narration_pending: bool = false

@onready var planet: Planet = %Planet
@onready var player: Player = %Player
@onready var dialogue: DialogueBox = %DialogueBox
@onready var overhead: OverheadTypewriter = %OverheadTypewriter
@onready var flock: MigratoryFlock = %MigratoryFlock


func _ready() -> void:
	overhead.play_on_ready = false
	_glass_globe().visible = false
	%Epilogue.text = ""
	%Dim.color = Color(0, 0, 0, 0)
	if auto_start:
		start()


func _process(_delta: float) -> void:
	if is_active and not _has_played_first_sunset_narration:
		try_first_sunset_narration(SkyPhase.angle_to_phase(planet.sky.rotation))


func start() -> void:
	is_active = true
	pulled_shoot_count = 0
	_has_played_first_sunset_narration = false
	_is_first_sunset_narration_pending = false
	_last_sky_phase = SkyPhase.angle_to_phase(planet.sky.rotation)
	beat = Beat.OPENING
	_glass_globe().visible = false
	player.can_move_left = false
	player.can_move_right = false
	player.move_speed_scale = OPENING_MOVE_SPEED_SCALE
	_lock_input()
	await _play_dialogue(B612Lines.opening_rose())
	await _play_overhead_after_dialogue(B612Lines.OPENING_OVERHEAD_VANITY)
	await _play_dialogue(B612Lines.opening_screen())
	if skip_cinematics:
		_finish_opening_cover()
		return
	is_blocking_input = false
	beat = Beat.COVER_ROSE


func accepts_interact(prop: SurfaceProp) -> bool:
	if not is_active or is_blocking_input:
		return false
	return _is_current_objective(prop)


func try_handle_interact(prop: SurfaceProp) -> bool:
	if not accepts_interact(prop):
		return false
	if skip_cinematics or beat == Beat.COVER_ROSE:
		apply_interact(prop)
		return true
	_lock_input()
	_play_interact(prop)
	return true


func apply_interact(prop: SurfaceProp) -> Array[DialogueLine]:
	var empty: Array[DialogueLine] = []
	if not _is_current_objective(prop):
		return empty
	match beat:
		Beat.COVER_ROSE:
			_finish_opening_cover()
			return empty
		Beat.PULL_SHOOTS:
			prop.is_consumed = true
			prop.visible = false
			pulled_shoot_count += 1
			if pulled_shoot_count >= SHOOT_COUNT:
				beat = Beat.FAREWELL
			return empty
		Beat.FAREWELL:
			prop.is_consumed = true
			beat = Beat.DEPART
			_glass_globe().visible = false
			return B612Lines.farewell()
		_:
			return empty


func try_first_sunset_narration(phase: float) -> void:
	if _has_played_first_sunset_narration:
		return
	if _last_sky_phase < SkyPhase.SUNSET_PHASE and phase >= SkyPhase.SUNSET_PHASE:
		_is_first_sunset_narration_pending = true
	_last_sky_phase = phase
	if not _is_first_sunset_narration_pending:
		return
	if beat == Beat.OPENING or beat == Beat.COVER_ROSE:
		return
	if is_blocking_input or dialogue.is_open():
		return
	_is_first_sunset_narration_pending = false
	_has_played_first_sunset_narration = true
	player.can_move_left = true
	player.move_speed_scale = 1.0
	_play_first_sunset_cinematic()


func _play_first_sunset_cinematic() -> void:
	if skip_cinematics:
		return
	_lock_input()
	await get_tree().create_timer(SUNSET_CINEMATIC_PRE_LIFT_DELAY_SECONDS).timeout
	await _tween_game_camera_offset_y(-SUNSET_CAMERA_LIFT_PIXELS, SUNSET_CAMERA_LIFT_SECONDS)
	for sunset_overhead_line in B612Lines.SUNSET_OVERHEAD_LINES:
		await _play_overhead(sunset_overhead_line)
	await get_tree().create_timer(SUNSET_CINEMATIC_POST_NARRATION_DELAY_SECONDS).timeout
	is_blocking_input = false
	await _tween_game_camera_offset_y(0.0, SUNSET_CAMERA_LIFT_SECONDS)


func _tween_game_camera_offset_y(target_offset_y: float, duration_seconds: float) -> void:
	var camera_tween := create_tween()
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(%GameCamera, "offset:y", target_offset_y, duration_seconds)
	await camera_tween.finished


func _play_interact(prop: SurfaceProp) -> void:
	if beat == Beat.FAREWELL:
		_glass_globe().visible = false
		var previous_cue_was_dialogue := false
		for cue in B612Lines.farewell_cues():
			if not cue.overhead_text.is_empty():
				if previous_cue_was_dialogue:
					await _play_overhead_after_dialogue(cue.overhead_text)
				else:
					await _play_overhead(cue.overhead_text)
				previous_cue_was_dialogue = false
			if not cue.dialogue_lines.is_empty():
				await _play_dialogue(cue.dialogue_lines)
				previous_cue_was_dialogue = true
		apply_interact(prop)
		await _play_departure()
		return
	await _play_overhead(B612Lines.pull_shoot(SHOOT_COUNT - pulled_shoot_count - 1))
	apply_interact(prop)
	is_blocking_input = false


func _play_departure() -> void:
	if skip_cinematics:
		player.modulate.a = 0.0
		%Dim.color = Color(0, 0, 0, 1)
		%Epilogue.text = B612Lines.OVERHEAD_PLANET_NAME
		return
	await flock.arrive_from_offscreen(player.global_position)
	flock.lift(DEPART_LIFT_PIXELS, DEPART_LIFT_SECONDS)
	var lift_tween := create_tween().set_parallel(true)
	lift_tween.tween_property(
			player, "position:y", player.position.y - DEPART_LIFT_PIXELS, DEPART_LIFT_SECONDS
	)
	lift_tween.tween_property(player, "modulate:a", 0.0, DEPART_LIFT_SECONDS)
	await lift_tween.finished
	var fade_tween := create_tween()
	fade_tween.tween_property(%Dim, "color:a", 1.0, FADE_TO_BLACK_SECONDS)
	await fade_tween.finished
	%Epilogue.text = B612Lines.OVERHEAD_PLANET_NAME


func _play_dialogue(lines: Array[DialogueLine]) -> void:
	if skip_cinematics or lines.is_empty():
		return
	dialogue.play(lines)
	if dialogue.is_open() and Input.is_action_pressed(&"interact"):
		dialogue.mark_holding(true)
	await dialogue.closed


func _play_overhead(display_text: String) -> void:
	if skip_cinematics or display_text.is_empty():
		return
	await overhead.play_queued(display_text)


func _play_overhead_after_dialogue(display_text: String) -> void:
	if skip_cinematics or display_text.is_empty():
		return
	await get_tree().create_timer(OPENING_OVERHEAD_START_DELAY_SECONDS).timeout
	await _play_overhead(display_text)


func _is_current_objective(prop: SurfaceProp) -> bool:
	if prop.is_consumed:
		return false
	match beat:
		Beat.COVER_ROSE:
			return prop.kind == SurfaceProp.Kind.ROSE and not _glass_globe().visible
		Beat.FAREWELL:
			return prop.kind == SurfaceProp.Kind.ROSE
		Beat.PULL_SHOOTS:
			return prop.kind == SurfaceProp.Kind.BAOBAB
		_:
			return false


func _finish_opening_cover() -> void:
	_glass_globe().visible = true
	player.can_move_right = true
	is_blocking_input = false
	if skip_cinematics:
		beat = Beat.PULL_SHOOTS
		return
	_play_opening_rose_overhead()


func _play_opening_rose_overhead() -> void:
	await get_tree().create_timer(OPENING_OVERHEAD_START_DELAY_SECONDS).timeout
	for opening_overhead_line in B612Lines.OPENING_OVERHEAD_LINES:
		await _play_overhead(opening_overhead_line)
	if beat == Beat.COVER_ROSE:
		beat = Beat.PULL_SHOOTS


func _lock_input() -> void:
	is_blocking_input = true
	planet.angular_velocity = 0.0


func _glass_globe() -> Sprite2D:
	return planet.get_node("Surface/Rose/GlassGlobe") as Sprite2D
