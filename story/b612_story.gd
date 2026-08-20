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
const SHOOT_COUNT := WorldConstants.BAOBAB_COUNT
const SUNSET_RED_PHASE_END := 0.88
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
var _last_sky_phase: float = SkyPhase.NOON_PHASE
var _walk_chatter_generation: int = 0
var _walk_line_index: int = 0

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
	_walk_chatter_generation = 0
	_walk_line_index = 0
	beat = Beat.OPENING
	_lock_input()
	await _play_overhead(B612Lines.OVERHEAD_PLANET_NAME)
	await _play_overhead(B612Lines.OVERHEAD_MY_PLANET)
	await _play_dialogue(B612Lines.opening())
	beat = Beat.PULL_SHOOTS
	await _play_overhead(B612Lines.OVERHEAD_PULL_HINT)
	is_blocking_input = false
	_begin_walk_chatter()


func accepts_interact(prop: SurfaceProp) -> bool:
	if not is_active or is_blocking_input:
		return false
	return _is_current_objective(prop)


func try_handle_interact(prop: SurfaceProp) -> bool:
	if not accepts_interact(prop):
		return false
	_walk_chatter_generation += 1
	_lock_input()
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
			if pulled_shoot_count >= SHOOT_COUNT:
				beat = Beat.CLEAN_VOLCANOES
			return empty
		Beat.CLEAN_VOLCANOES:
			prop.is_consumed = true
			cleaned_volcano_count += 1
			for child in prop.get_children():
				var smoke := child as CPUParticles2D
				if smoke != null:
					smoke.emitting = false
			if cleaned_volcano_count >= WorldConstants.VOLCANO_COUNT:
				beat = Beat.TEND_ROSE
			return empty
		Beat.TEND_ROSE:
			beat = Beat.WATCH_SUNSET
			_last_sky_phase = SkyPhase.angle_to_phase(planet.sky.rotation)
			if not _glass_globe().visible:
				_glass_globe().visible = true
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
	var crossed_into_red := (
			_last_sky_phase < SkyPhase.SUNSET_PHASE and phase >= SkyPhase.SUNSET_PHASE
	)
	_last_sky_phase = phase
	if (
			not crossed_into_red
			and (phase < SkyPhase.SUNSET_PHASE or phase > SUNSET_RED_PHASE_END)
	):
		return
	beat = Beat.FAREWELL
	_lock_input()
	_play_sunset_reached()


func _play_interact(prop: SurfaceProp) -> void:
	if beat == Beat.TEND_ROSE:
		await _play_dialogue(B612Lines.tend_rose_until_cover())
		_glass_globe().visible = true
		await _play_dialogue(B612Lines.tend_rose_after_cover())
		apply_interact(prop)
		await _play_overhead(B612Lines.OVERHEAD_ROSE_THANKLESS)
		await _play_overhead(B612Lines.OVERHEAD_WALK_TO_SUNSET)
		is_blocking_input = false
		return
	if beat == Beat.FAREWELL:
		await _play_dialogue(B612Lines.farewell_until_uncover())
		_glass_globe().visible = false
		await _play_dialogue(B612Lines.farewell_after_uncover())
		apply_interact(prop)
		await _play_departure()
		return
	if not skip_cinematics and prop.kind == SurfaceProp.Kind.BAOBAB:
		var pull_tween := create_tween()
		pull_tween.tween_property(prop, "modulate:a", 0.0, BAOBAB_PULL_FADE_SECONDS)
		await pull_tween.finished
	var was_active_volcano := (
			prop.kind == SurfaceProp.Kind.VOLCANO
			and prop.variant == WorldConstants.VOLCANO_ACTIVE_VARIANT
	)
	apply_interact(prop)
	if prop.kind == SurfaceProp.Kind.BAOBAB:
		await _play_overhead(B612Lines.pull_shoot(SHOOT_COUNT - pulled_shoot_count))
	elif prop.kind == SurfaceProp.Kind.VOLCANO:
		await _play_overhead(
				B612Lines.clean_volcano(
						was_active_volcano,
						WorldConstants.VOLCANO_COUNT - cleaned_volcano_count
				)
		)
	is_blocking_input = false
	_begin_walk_chatter()


func _play_sunset_reached() -> void:
	if skip_cinematics:
		is_blocking_input = false
		return
	await _play_overhead(B612Lines.OVERHEAD_SUNSET)
	await _play_overhead(B612Lines.OVERHEAD_FAREWELL_HINT)
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
	if dialogue.is_open():
		dialogue.mark_holding(true)
	await dialogue.closed


func _play_overhead(display_text: String) -> void:
	if skip_cinematics or display_text.is_empty():
		return
	await overhead.play(display_text)


func _begin_walk_chatter() -> void:
	_walk_chatter_generation += 1
	var generation := _walk_chatter_generation
	if skip_cinematics or not is_active:
		return
	const walk_chatter_interval_seconds := 3.2
	const walk_chatter_stop_seconds := 2.0
	while generation == _walk_chatter_generation and is_inside_tree() and not is_blocking_input:
		await get_tree().create_timer(walk_chatter_interval_seconds).timeout
		if (
				generation != _walk_chatter_generation
				or is_blocking_input
				or not is_inside_tree()
		):
			return
		if not planet.is_moving():
			continue
		if _seconds_to_nearest_objective() < walk_chatter_stop_seconds:
			return
		var pool: PackedStringArray
		match beat:
			Beat.PULL_SHOOTS:
				pool = B612Lines.shoot_walk_lines()
			Beat.CLEAN_VOLCANOES:
				pool = B612Lines.volcano_walk_lines()
			Beat.TEND_ROSE:
				pool = B612Lines.rose_walk_lines()
			_:
				return
		if pool.is_empty():
			return
		overhead.play(pool[_walk_line_index % pool.size()])
		_walk_line_index += 1


func _seconds_to_nearest_objective() -> float:
	var nearest_arc := TAU
	for prop in planet.surface_props:
		if not _is_current_objective(prop):
			continue
		var diff := absf(angle_difference(planet.player_angle, prop.rotation))
		if diff < nearest_arc:
			nearest_arc = diff
	return nearest_arc * planet.radius / WorldConstants.PLAYER_SPEED


func _is_current_objective(prop: SurfaceProp) -> bool:
	if prop.is_consumed:
		return false
	match beat:
		Beat.PULL_SHOOTS:
			return prop.kind == SurfaceProp.Kind.BAOBAB
		Beat.CLEAN_VOLCANOES:
			return prop.kind == SurfaceProp.Kind.VOLCANO
		Beat.TEND_ROSE, Beat.FAREWELL:
			return prop.kind == SurfaceProp.Kind.ROSE
		_:
			return false


func _lock_input() -> void:
	is_blocking_input = true
	planet.angular_velocity = 0.0


func _glass_globe() -> Sprite2D:
	return planet.get_node("Surface/Rose/GlassGlobe") as Sprite2D
