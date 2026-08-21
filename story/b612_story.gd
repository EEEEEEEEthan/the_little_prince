class_name B612Story
extends PlanetStory
## B612 故乡剧情：一条协程串起对白、侧写、交互与离星。

const PULL_SHOOT_HOLD_SECONDS := 0.8
const GLASS_GLOBE_HOLD_SECONDS := 0.8

var _is_glass_interact: bool = false


func _ready() -> void:
	_glass_globe().visible = false
	super._ready()


func interact_hold_seconds(prop: SurfaceProp) -> float:
	if skip_cinematics or not accepts_interact(prop):
		return 0.0
	if prop.kind == SurfaceProp.Kind.BAOBAB:
		return PULL_SHOOT_HOLD_SECONDS
	if _is_glass_interact:
		return GLASS_GLOBE_HOLD_SECONDS
	return 0.0


func _prepare_start() -> void:
	_is_glass_interact = false
	_glass_globe().visible = false
	planet.sky.is_self_rotating = false
	player.move_speed_scale = 0.8


func _play_story() -> void:
	await _fade_in_from_black()
	await _rose("我刚刚睡醒，真对不起，我的头发还是乱蓬蓬的。。。")
	await _prince("可你还是很美丽")
	await _rose("是吧，我是与太阳同时出生的。。。")
	await _wait(1.0)
	await _overhead("咳..咳..")
	await _rose("我有点冷，你有屏风吗")
	await _prince("屏风?")
	await _rose("我原来住的那个地方是有屏风的")
	await _rose("那里可不像这里...")
	await _overhead("她从没住过别的地方")
	await _rose("...")
	await _overhead("她意识到自己在编一个不太高明的谎话")
	await _overhead("咳...咳...")
	await _overhead("她有点羞怒,于是故意咳得很大声")
	await _prince("...")
	await _rose("屏风呢!")
	await _prince("我这就去拿...")
	_overhead("咳...咳...")
	if skip_cinematics:
		_show_glass()
	else:
		await _wait(0.2)
		is_blocking_input = false
		_is_glass_interact = true
		await _interact_rose()
		_is_glass_interact = false
		_show_glass()
	player.can_move_right = true
	is_blocking_input = false
	if not skip_cinematics:
		(planet.get_node("%Butterfly3") as Butterfly).begin_guide_flight()
	await _overhead("她安静下来")
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
	await _depart("B-612。")


func _rose(text: String) -> void:
	await _line(DialogueCatalog.ROSE_SPEAKER, text, DialogueCatalog.ROSE_PORTRAIT)


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


func _show_glass() -> void:
	_glass_globe().visible = true
	planet.sky.is_self_rotating = true


func _hide_glass() -> void:
	_glass_globe().visible = false


func _rose_prop() -> SurfaceProp:
	return planet.get_node("Surface/Rose") as SurfaceProp


func _glass_globe() -> Sprite2D:
	return _rose_prop().get_node("GlassGlobe") as Sprite2D
