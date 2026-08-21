class_name B612Story
extends Node
## B612 故乡剧情：一条协程串起对白、侧写、交互与离星。

signal prop_interacted(prop)
signal sunset_crossed
signal _halt

const PULL_SHOOT_HOLD_SECONDS := 0.8

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
	_glass_globe().visible = false
	%Epilogue.text = ""
	if auto_start:
		%Dim.color = Color(0, 0, 0, 1)
		start()
	else:
		%Dim.color = Color(0, 0, 0, 0)


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
	_glass_globe().visible = false
	player.can_move_left = false
	player.can_move_right = false
	player.move_speed_scale = 0.8
	_play_story()
	while not has_finished_opening and is_inside_tree():
		await get_tree().process_frame


func accepts_interact(prop: SurfaceProp) -> bool:
	if not is_active or is_blocking_input or prop.is_consumed:
		return false
	return int(prop.kind) == _waiting_interact_kind


func interact_hold_seconds(prop: SurfaceProp) -> float:
	if skip_cinematics or not accepts_interact(prop):
		return 0.0
	if prop.kind == SurfaceProp.Kind.BAOBAB:
		return PULL_SHOOT_HOLD_SECONDS
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


func _play_story() -> void:
	_lock_input()
	%Dim.color = Color(0, 0, 0, 1)
	if skip_cinematics:
		%Dim.color.a = 0.0
	else:
		var fade_in_from_black_seconds := 2.4
		_story_tween = create_tween()
		_story_tween.tween_property(%Dim, "color:a", 0.0, fade_in_from_black_seconds)
		await _wait(fade_in_from_black_seconds * 0.5)
	await _rose("我刚刚睡醒，真对不起，我的头发还是乱蓬蓬的。。。")
	await _prince("可你还是很美丽")
	await _rose("是吧，我是与太阳同时出生的。。。")
	await _wait(1.0)
	await _overhead("咳..咳..")
	await _rose("我有点冷，你有屏风吗")
	await _prince("...")
	await _rose("这里太冷了,我住的不太好")
	await _rose("我原来住的那个地方...")
	await _overhead("她意识到她在编一个不太高明的谎话")
	await _overhead("她有点羞怒,于是开始假装咳嗽")
	await _rose("屏风呢!")
	await _prince("我这就去拿...")
	_overhead("咳...咳...")
	if skip_cinematics:
		_show_glass()
	else:
		await _wait(0.2)
		is_blocking_input = false
		await _interact_rose()
		_show_glass()
	player.can_move_right = true
	is_blocking_input = false
	if not skip_cinematics:
		(planet.get_node("%Butterfly3") as Butterfly).begin_guide_flight()
	await _wait_move_right()
	await _wait(3.0)
	await _overhead("小王子很喜欢玫瑰花")
	await _overhead("可是她的傲娇，她的尖刺，总是让他恼火")
	has_finished_opening = true
	await _meet_sunset()
	player.can_move_right = false
	_lock_input()
	await _wait(0.3)
	await _camera_up()
	await _overhead("人在忧伤的时候，就喜欢看日落。")
	await _overhead("有一次小王子看了四十三遍日落")
	await _wait(0.5)
	await _camera_down()
	is_blocking_input = false
	player.can_move_left = true
	player.can_move_right = true
	player.move_speed_scale = 1.0
	var pull_baobab_then_narrate := func(overhead_text: String) -> void:
		var pulled_baobab := await _interact_baobab()
		pulled_baobab.is_consumed = true
		pulled_baobab.visible = false
		await _overhead(overhead_text)
		is_blocking_input = false
	await pull_baobab_then_narrate.call("小王子的星球总会长出猴面包树")
	await pull_baobab_then_narrate.call("小王子每天都要拔掉猴面包树苗")
	await pull_baobab_then_narrate.call("不拔的话，星球就会被猴面包树弄得支离破碎")
	await pull_baobab_then_narrate.call("可是现在他决定要离开了")
	await pull_baobab_then_narrate.call("这是最后一株")
	var rose := await _interact_rose()
	_hide_glass()
	await _overhead("小王子最后一次浇花，他发觉自己要哭出来")
	await _prince("再见了")
	await _wait(3.0)
	await _overhead("花儿没有答应他")
	await _prince("再见了")
	await _wait(3.0)
	await _overhead("花儿咳嗽了一阵，但并不是由于感冒")
	await _rose("我真傻")
	await _rose("请你原谅我。")
	await _rose("希望你能幸福。")
	await _wait(2.0)
	await _overhead("小王子不知所措，不明白她为什么突然这样温柔恬静")
	await _rose("的确，我爱你")
	await _rose("但由于我的过错，你一点也没有理会我的爱")
	await _rose("这不重要")
	await _rose("希望你今后能幸福")
	await _rose("把罩子放一边吧，我用不着他了")
	await _prince("要是风来了怎么办？")
	await _rose("我的感冒并不那么重")
	await _prince("要是有虫子野兽呢？")
	await _rose("我有爪子")
	await _overhead("玫瑰天真地露出她那四根刺")
	await _rose("别这么磨蹭了。真烦人！")
	await _rose("既然决定离开这儿，那么，快走吧！")
	await _wait(1.0)
	await _overhead("玫瑰不想小王子看见她在哭")
	_overhead("她总是这么傲娇")
	rose.is_consumed = true
	await _depart()


func _rose(text: String) -> void:
	await _line(DialogueCatalog.ROSE_SPEAKER, text, DialogueCatalog.ROSE_PORTRAIT)


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


func _wait_move_right() -> void:
	var generation := _story_generation
	_end_dialogue()
	if skip_cinematics:
		await _halt_if_stale(generation)
		return
	while is_inside_tree() and Input.get_action_strength(&"move_right") <= 0.0:
		await get_tree().process_frame
		if generation != _story_generation:
			await _halt
			return
	await _halt_if_stale(generation)


func _interact_rose() -> SurfaceProp:
	return await _interact(SurfaceProp.Kind.ROSE)


func _interact_baobab() -> SurfaceProp:
	return await _interact(SurfaceProp.Kind.BAOBAB)


func _meet_sunset() -> void:
	var generation := _story_generation
	if not has_crossed_sunset:
		await sunset_crossed
	await _halt_if_stale(generation)


func _camera_up() -> void:
	await _tween_game_camera_offset_y(-16.0, 1.0)


func _camera_down() -> void:
	await _tween_game_camera_offset_y(0.0, 1.0)


func _show_glass() -> void:
	_glass_globe().visible = true


func _hide_glass() -> void:
	_glass_globe().visible = false


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


func _depart() -> void:
	var generation := _story_generation
	_end_dialogue()
	if skip_cinematics:
		player.modulate.a = 0.0
		%Dim.color = Color(0, 0, 0, 1)
		%Epilogue.text = "B-612。"
		await _halt_if_stale(generation)
		return
	await flock.arrive_from_offscreen(player.global_position)
	flock.lift(72.0, 2.4)
	var lift_tween := create_tween().set_parallel(true)
	lift_tween.tween_property(player, "position:y", player.position.y - 72.0, 2.4)
	lift_tween.tween_property(player, "modulate:a", 0.0, 2.4)
	await lift_tween.finished
	_story_tween = create_tween()
	_story_tween.tween_property(%Dim, "color:a", 1.0, 1.2)
	await _story_tween.finished
	_story_tween = null
	%Epilogue.text = "B-612。"
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


func _rose_prop() -> SurfaceProp:
	return planet.get_node("Surface/Rose") as SurfaceProp


func _glass_globe() -> Sprite2D:
	return _rose_prop().get_node("GlassGlobe") as Sprite2D
