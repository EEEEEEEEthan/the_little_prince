class_name PlanetStory
extends Node
## 星球演出公共协程：对白、头顶叙事、等待交互、离星。

signal prop_interacted(prop)
signal sunset_crossed
signal departed
signal _halt

const EPILOGUE_HOLD_SECONDS := 1.8
const LIFT_DURATION_SECONDS := 2.4
const LIFT_HALFWAY_OVERHEAD_EXTRA_SECONDS := 0.5
const DEPARTURE_BLACKOUT_SECONDS := 1.2

@export var auto_start: bool = true

var skip_cinematics: bool = false
var is_active: bool = false
var is_blocking_input: bool = false
var has_finished_opening: bool = false
var has_crossed_sunset: bool = false

var planet: Planet:
	get:
		return owner as Planet
var player: Player:
	get:
		return _shell_node(&"Player") as Player
var dialogue: DialogueBox:
	get:
		return _shell_node(&"DialogueBox") as DialogueBox
var overhead: OverheadTypewriter:
	get:
		return _shell_node(&"OverheadTypewriter") as OverheadTypewriter
var flock: MigratoryFlock:
	get:
		return _shell_node(&"MigratoryFlock") as MigratoryFlock

var _story_generation: int = 0
var _waiting_interact_kind: int = -1
var _dialogue_closed_early: bool = false
var _story_tween: Tween


func _ready() -> void:
	if planet.owner == null:
		return
	overhead.play_on_ready = false


func _process(_delta: float) -> void:
	if not is_active or has_crossed_sunset or not planet.is_node_ready():
		return
	try_first_sunset_narration()


func _shell_node(unique_name: StringName) -> Node:
	return planet.owner.get_node("%" + String(unique_name))


func start() -> void:
	overhead.play_on_ready = false
	_story_generation += 1
	sunset_crossed.emit()
	prop_interacted.emit(null)
	if dialogue.is_open():
		dialogue.close()
	overhead.play("")
	if _story_tween != null:
		_story_tween.kill()
		_story_tween = null
	if not planet.is_node_ready():
		await planet.ready
	_shell_node(&"Epilogue").text = ""
	_shell_node(&"Dim").color = Color(0, 0, 0, 1)
	is_active = true
	has_finished_opening = false
	has_crossed_sunset = false
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


func try_first_sunset_narration() -> void:
	if has_crossed_sunset:
		return
	if player.has_overlapping_trigger_kind(WorldConstants.TriggerKind.SUNSET):
		has_crossed_sunset = true
		sunset_crossed.emit()


func _prepare_start() -> void:
	pass


func _play_story() -> void:
	pass


func _fade_in_from_black() -> void:
	_lock_input()
	_shell_node(&"Dim").color = Color(0, 0, 0, 1)
	if skip_cinematics:
		_shell_node(&"Dim").color.a = 0.0
		return
	var fade_in_from_black_seconds := 2.4
	_story_tween = create_tween()
	_story_tween.tween_property(_shell_node(&"Dim"), "color:a", 0.0, fade_in_from_black_seconds)
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
	_story_tween.tween_property(_shell_node(&"GameCamera"), "offset:y", target_offset_y, duration_seconds)
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
		_shell_node(&"Dim").color = Color(0, 0, 0, 1)
	else:
		var lift_distance_pixels := (
				player.global_position.y
				- get_viewport().get_visible_rect().position.y
				+ float(WorldConstants.PLAYER_SPRITE_HEIGHT)
		)
		await flock.arrive_from_offscreen(player.global_position)
		flock.lift(lift_distance_pixels, LIFT_DURATION_SECONDS)
		var lift_tween := create_tween()
		lift_tween.tween_property(
				player,
				"position:y",
				player.position.y - lift_distance_pixels,
				LIFT_DURATION_SECONDS
		)
		if lift_halfway_overhead_texts.is_empty():
			lift_tween.parallel().tween_property(
					player, "modulate:a", 0.0, LIFT_DURATION_SECONDS
			)
			await lift_tween.finished
		else:
			await _wait(
					LIFT_DURATION_SECONDS * 0.5 + LIFT_HALFWAY_OVERHEAD_EXTRA_SECONDS
			)
			for overhead_text in lift_halfway_overhead_texts:
				await _overhead(overhead_text)
		_story_tween = create_tween()
		_story_tween.tween_property(
				_shell_node(&"Dim"), "color:a", 1.0, DEPARTURE_BLACKOUT_SECONDS
		)
		_shell_node(&"Music").fade_out(DEPARTURE_BLACKOUT_SECONDS)
		await _story_tween.finished
		_story_tween = null
		player.modulate.a = 0.0
	_shell_node(&"Epilogue").text = epilogue_text
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
