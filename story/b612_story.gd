class_name B612Story
extends Node
## B612 故乡剧情：开场 → 拔苗 → 疏通火山 → 侍弄玫瑰 → 看日落 → 告别 → 离星。

enum Beat {
	OPENING,
	PULL_SHOOTS,
	CLEAN_VOLCANOES,
	TEND_ROSE,
	WATCH_SUNSET,
	FAREWELL,
	DEPART,
}

const SHOOT_DIALOGUE_ID := &"baobab_shoot"
const SHOOT_COUNT := 3
const SUNSET_PHASE_SLACK := 0.08
const DEPART_LIFT_PIXELS := 72.0
const DEPART_LIFT_SECONDS := 2.4
const BAOBAB_PULL_FADE_SECONDS := 0.28
const FADE_TO_BLACK_SECONDS := 1.2

@export var auto_start: bool = true

var skip_cinematics: bool = false
var is_active: bool = false
var is_blocking_input: bool = false
var beat: Beat = Beat.OPENING
var pulled_shoot_count: int = 0
var cleaned_volcano_count: int = 0
var _must_leave_sunset_band: bool = false

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
	if is_active and beat == Beat.WATCH_SUNSET:
		advance_sunset_if_ready(SkyPhase.angle_to_phase(planet.sky.rotation))


func start() -> void:
	is_active = true
	pulled_shoot_count = 0
	cleaned_volcano_count = 0
	beat = Beat.OPENING
	is_blocking_input = true
	_must_leave_sunset_band = false
	await _play_overhead(B612Lines.OVERHEAD_PLANET_NAME)
	await _play_overhead(B612Lines.OVERHEAD_MY_PLANET)
	await _play_dialogue(B612Lines.opening())
	beat = Beat.PULL_SHOOTS
	is_blocking_input = false
	if not skip_cinematics:
		overhead.play(B612Lines.OVERHEAD_PULL_HINT)


func accepts_interact(prop: SurfaceProp) -> bool:
	if not is_active or is_blocking_input:
		return false
	return _is_current_objective(prop)


func try_handle_interact(prop: SurfaceProp) -> bool:
	if not accepts_interact(prop):
		return false
	is_blocking_input = true
	_play_interact(prop)
	return true


func apply_interact(prop: SurfaceProp) -> Array[DialogueLine]:
	var empty: Array[DialogueLine] = []
	if not _is_current_objective(prop):
		return empty
	match beat:
		Beat.PULL_SHOOTS:
			prop.is_consumed = true
			prop.visible = false
			pulled_shoot_count += 1
			var remaining_shoot_count := SHOOT_COUNT - pulled_shoot_count
			if remaining_shoot_count > 0:
				return B612Lines.pull_shoot(remaining_shoot_count)
			beat = Beat.CLEAN_VOLCANOES
			return B612Lines.shoots_finished()
		Beat.CLEAN_VOLCANOES:
			prop.is_consumed = true
			cleaned_volcano_count += 1
			for child in prop.get_children():
				var smoke := child as CPUParticles2D
				if smoke != null:
					smoke.emitting = false
			var lines := B612Lines.clean_volcano(
					prop.variant == WorldConstants.VOLCANO_ACTIVE_VARIANT
			)
			if cleaned_volcano_count >= WorldConstants.VOLCANO_COUNT:
				beat = Beat.TEND_ROSE
				lines.append_array(B612Lines.volcanoes_finished())
			return lines
		Beat.TEND_ROSE:
			beat = Beat.WATCH_SUNSET
			_glass_globe().visible = true
			_must_leave_sunset_band = true
			return B612Lines.tend_rose()
		Beat.FAREWELL:
			prop.is_consumed = true
			beat = Beat.DEPART
			_glass_globe().visible = false
			return B612Lines.farewell()
		_:
			return empty


func advance_sunset_if_ready(phase: float) -> void:
	if beat != Beat.WATCH_SUNSET:
		return
	var in_sunset_band := absf(phase - SkyPhase.SUNSET_PHASE) <= SUNSET_PHASE_SLACK
	if _must_leave_sunset_band:
		if not in_sunset_band:
			_must_leave_sunset_band = false
		return
	if not in_sunset_band:
		return
	beat = Beat.FAREWELL
	flock.appear()
	is_blocking_input = true
	_play_sunset_reached()


func _play_interact(prop: SurfaceProp) -> void:
	if not skip_cinematics and prop.dialogue_id == SHOOT_DIALOGUE_ID:
		var pull_tween := create_tween()
		pull_tween.tween_property(prop, "modulate:a", 0.0, BAOBAB_PULL_FADE_SECONDS)
		await pull_tween.finished
	var lines := apply_interact(prop)
	await _play_dialogue(lines)
	if beat == Beat.WATCH_SUNSET:
		await _play_overhead(B612Lines.OVERHEAD_ROSE_THANKLESS)
		await _play_overhead(B612Lines.OVERHEAD_WALK_TO_SUNSET)
	if beat == Beat.DEPART:
		await _play_departure()
		return
	is_blocking_input = false


func _play_sunset_reached() -> void:
	if skip_cinematics:
		is_blocking_input = false
		return
	await _play_overhead(B612Lines.OVERHEAD_SUNSET)
	await _play_overhead(B612Lines.OVERHEAD_FAREWELL_HINT)
	is_blocking_input = false


func _play_departure() -> void:
	flock.appear()
	if skip_cinematics:
		player.modulate.a = 0.0
		%Dim.color = Color(0, 0, 0, 1)
		%Epilogue.text = B612Lines.OVERHEAD_PLANET_NAME
		return
	await flock.gather_to_apex(player.global_position)
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
	if dialogue.is_open():
		dialogue.mark_holding(true)
	await dialogue.closed


func _play_overhead(display_text: String) -> void:
	if skip_cinematics or display_text.is_empty():
		return
	await overhead.play(display_text)


func _is_current_objective(prop: SurfaceProp) -> bool:
	if prop.is_consumed:
		return false
	match beat:
		Beat.PULL_SHOOTS:
			return prop.dialogue_id == SHOOT_DIALOGUE_ID
		Beat.CLEAN_VOLCANOES:
			return prop.kind == SurfaceProp.Kind.VOLCANO
		Beat.TEND_ROSE, Beat.FAREWELL:
			return prop.kind == SurfaceProp.Kind.ROSE
		_:
			return false


func _glass_globe() -> Sprite2D:
	return planet.get_node("Surface/Rose/GlassGlobe") as Sprite2D
