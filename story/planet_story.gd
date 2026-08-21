class_name PlanetStory
extends Node
## 星球演出公共协程：对白、头顶叙事、等待交互、离星。

signal prop_interacted(prop)
signal sunset_crossed
signal departed
signal _halt

const EPILOGUE_HOLD_SECONDS := 1.8
const LIFT_DISTANCE_PIXELS := 72.0
const LIFT_DURATION_SECONDS := 2.4

@export var auto_start: bool = true

var skip_cinematics: bool = false
var is_active: bool = false
var is_blocking_input: bool = false
var has_finished_opening: bool = false
var has_crossed_sunset: bool = false

var _story_generation: int = 0
var _last_sky_phase: float = SkyPhase.NOON_PHASE
var _waiting_interact_kind: int = -1
var _dialogue_closed_early: bool = false
var _story_tween: Tween

@onready var planet: Planet = %Planet
@onready var player: Player = %Player
@onready var dialogue: DialogueBox = %DialogueBox
@onready var overhead: OverheadTypewriter = %OverheadTypewriter
@onready var flock: MigratoryFlock = %MigratoryFlock


func _ready() -> void:
	overhead.play_on_ready = false
	if not auto_start:
		return
	%Epilogue.text = ""
	%Dim.color = Color(0, 0, 0, 1)
	start()


func _process(_delta: float) -> void:
	if is_active and not has_crossed_sunset:
		try_first_sunset_narration(SkyPhase.angle_to_phase(planet.sky.rotation))


func start() -> void:
	_story_generation += 1
	sunset_crossed.emit()
	prop_interacted.emit(null)
	if dialogue.is_open():
		dialogue.close()
	overhead.play("")
	if _story_tween != null:
		_story_tween.kill()
		_story_tween = null
	is_active = true
	has_finished_opening = false
	has_crossed_sunset = false
	_last_sky_phase = SkyPhase.angle_to_phase(planet.sky.rotation)
	_waiting_interact_kind = -1
	_dialogue_closed_early = false
	player.can_move_left = false
	player.can_move_right = false
	player.move_speed_scale = 1.0
	_prepare_start()
	_play_story()
	while not has_finished_opening and is_inside_tree():
		await get_tree().process_frame


func accepts_interact(prop: SurfaceProp) -> bool:
	if not is_active or is_blocking_input or prop.is_consumed:
		return false
	return int(prop.kind) == _waiting_interact_kind


func interact_hold_seconds(_prop: SurfaceProp) -> float:
	return 0.0


func try_handle_interact(prop: SurfaceProp) -> bool:
	if not accepts_interact(prop):
		return false
	_lock_input()
	_waiting_interact_kind = -1
	prop_interacted.emit(prop)
	return true


func try_first_sunset_narration(phase: float) -> void:
	if has_crossed_sunset:
		return
	if _last_sky_phase < SkyPhase.SUNSET_PHASE and phase >= SkyPhase.SUNSET_PHASE:
		has_crossed_sunset = true
		sunset_crossed.emit()
	_last_sky_phase = phase


func _prepare_start() -> void:
	pass


func _play_story() -> void:
	pass


func _fade_in_from_black() -> void:
	_lock_input()
	%Dim.color = Color(0, 0, 0, 1)
	if skip_cinematics:
		%Dim.color.a = 0.0
		return
	var fade_in_from_black_seconds := 2.4
	_story_tween = create_tween()
	_story_tween.tween_property(%Dim, "color:a", 0.0, fade_in_from_black_seconds)
	await _wait(fade_in_from_black_seconds * 0.5)


func _prince(text: String) -> void:
	await _line(DialogueCatalog.PRINCE_SPEAKER, text, DialogueCatalog.PRINCE_PORTRAIT)


func _overhead(display_text: String) -> void:
	var generation := _story_generation
	_end_dialogue()
	if skip_cinematics or display_text.is_empty():
		await _halt_if_stale(generation)
		return
	await overhead.play_queued(display_text)
	await _halt_if_stale(generation)


func _wait(duration_seconds: float) -> void:
	var generation := _story_generation
	_end_dialogue()
	if skip_cinematics:
		await _halt_if_stale(generation)
		return
	await get_tree().create_timer(duration_seconds).timeout
	await _halt_if_stale(generation)


func _meet_sunset() -> void:
	var generation := _story_generation
	if not has_crossed_sunset:
		await sunset_crossed
	await _halt_if_stale(generation)


func _camera_up() -> void:
	await _tween_game_camera_offset_y(-16.0, 1.0)


func _camera_down() -> void:
	await _tween_game_camera_offset_y(0.0, 1.0)


func _line(speaker: String, text: String, portrait: Texture2D) -> void:
	var generation := _story_generation
	if skip_cinematics or _dialogue_closed_early:
		await _halt_if_stale(generation)
		return
	_lock_input()
	var already_open := dialogue.is_open()
	dialogue.play_line(DialogueLine.new(speaker, text, portrait))
	if dialogue.is_open() and not already_open and Input.is_action_pressed(&"interact"):
		dialogue.mark_holding(true)
	await dialogue.line_advanced
	if not dialogue.is_open():
		_dialogue_closed_early = true
	await _halt_if_stale(generation)


func _interact(kind: SurfaceProp.Kind) -> SurfaceProp:
	var generation := _story_generation
	_end_dialogue()
	_waiting_interact_kind = int(kind)
	var prop: SurfaceProp = await prop_interacted
	_waiting_interact_kind = -1
	await _halt_if_stale(generation)
	return prop


func _tween_game_camera_offset_y(target_offset_y: float, duration_seconds: float) -> void:
	var generation := _story_generation
	if skip_cinematics:
		await _halt_if_stale(generation)
		return
	if _story_tween != null:
		_story_tween.kill()
	_story_tween = create_tween()
	_story_tween.set_trans(Tween.TRANS_CUBIC)
	_story_tween.set_ease(Tween.EASE_IN_OUT)
	_story_tween.tween_property(%GameCamera, "offset:y", target_offset_y, duration_seconds)
	await _story_tween.finished
	_story_tween = null
	await _halt_if_stale(generation)


func _depart(
		epilogue_text: String,
		lift_halfway_overhead_texts: PackedStringArray = PackedStringArray(),
) -> void:
	var generation := _story_generation
	_end_dialogue()
	if skip_cinematics:
		player.modulate.a = 0.0
		%Dim.color = Color(0, 0, 0, 1)
	else:
		await flock.arrive_from_offscreen(player.global_position)
		flock.lift(LIFT_DISTANCE_PIXELS, LIFT_DURATION_SECONDS)
		var lift_tween := create_tween()
		lift_tween.tween_property(
				player,
				"position:y",
				player.position.y - LIFT_DISTANCE_PIXELS,
				LIFT_DURATION_SECONDS
		)
		if lift_halfway_overhead_texts.is_empty():
			lift_tween.parallel().tween_property(
					player, "modulate:a", 0.0, LIFT_DURATION_SECONDS
			)
			await lift_tween.finished
		else:
			await _wait(LIFT_DURATION_SECONDS * 0.5)
			for overhead_text in lift_halfway_overhead_texts:
				await _overhead(overhead_text)
		_story_tween = create_tween()
		_story_tween.tween_property(%Dim, "color:a", 1.0, 1.2)
		await _story_tween.finished
		_story_tween = null
		player.modulate.a = 0.0
	%Epilogue.text = epilogue_text
	await _wait(EPILOGUE_HOLD_SECONDS)
	departed.emit()
	await _halt_if_stale(generation)


func _end_dialogue() -> void:
	_dialogue_closed_early = false
	if dialogue.is_open():
		dialogue.close()


func _halt_if_stale(generation: int) -> void:
	if generation == _story_generation:
		return
	await _halt


func _lock_input() -> void:
	is_blocking_input = true
	planet.angular_velocity = 0.0
