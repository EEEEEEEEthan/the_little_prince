extends SceneTree
## 325 国王星球剧情演出截图采集：真实渲染（xvfb + llvmpipe）跑完整章。
## 用法：
##   DISPLAY=:99 .engine/.engine --path . --rendering-driver opengl3 \
##     --script res://tests/capture_325_shots.gd
## 截图输出到 /workspace/reports/shots/。

const SHOT_DIR := "/workspace/reports/shots"
const VIEWPORT_PATH := "GameView/GameViewport"
const PLANET_PATH := "GameView/GameViewport/Planet"
const PLAYER_PATH := "GameView/GameViewport/Player"

var game_viewport: SubViewport
var planet: Planet
var player: Player
var story: PlanetStory
var dialogue: DialogueBox
var overhead: OverheadTypewriter


func _init() -> void:
	call_deferred(&"_run")


func get_tree() -> SceneTree:
	return self


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var packed: PackedScene = load("res://journey/main.tscn")
	if packed == null:
		printerr("无法加载 main.tscn")
		quit(1)
		return
	var scene := packed.instantiate()
	(
			scene.get_node(VIEWPORT_PATH + "/OverheadTypewriter") as OverheadTypewriter
	).play_on_ready = false
	(scene.get_node(PLANET_PATH).get_node("%Story") as PlanetStory).auto_start = false
	root.add_child(scene)
	await process_frame
	await process_frame

	scene.travel_to_king_planet(false)
	await process_frame
	await process_frame

	planet = scene.get_node(PLANET_PATH) as Planet
	player = scene.get_node(PLAYER_PATH) as Player
	story = planet.get_node("%Story") as PlanetStory
	game_viewport = scene.get_node(VIEWPORT_PATH) as SubViewport
	dialogue = scene.get_node(VIEWPORT_PATH + "/DialogueBox") as DialogueBox
	overhead = scene.get_node(VIEWPORT_PATH + "/OverheadTypewriter") as OverheadTypewriter

	story.start()

	# 开场：淡入 + 三句章节旁白（夜面降落）
	await _await_overhead_shown("第一颗星球上，住着一位国王。")
	await _shot("01_opening_intro")
	while not story.has_finished_opening:
		await process_frame

	# 出生点偷听：远处传来的判刑与赦免
	await _await_overhead_shown("「判你死刑。」")
	await _shot("02_rat_sentencing")

	# 走向国王：人还在地平线后，先闻其声
	planet.teleport_player(fposmod(planet.king_angle - 2.0, TAU))
	await _await_overhead_shown("「……来了一个臣民……」")
	await _shot("03_distant_king_voice")
	await _await_overhead_shown("所有的人都是臣民。")
	await _shot("04_subjects_narration")

	# 走进觐见禁区，触发整章对白
	planet.teleport_player(
			fposmod(planet.king_angle + planet.audience_keep_away_arc + 0.04, TAU)
	)
	for step in 24:
		planet.move_player(-1.0, 0.05)
	await _await_dialogue_shown("走近些，让我看清楚点。")
	await _shot("05_audience_approach")

	await _drive_dialogue({
			"我禁止你打哈欠。": "06_forbid_yawn",
			"统治一切。": "07_rule_over_all",
			"我很想看一次日落...请给我这个恩惠...命令太阳下山...": "08_sunset_request",
			"大约...今晚七点四十分左右！": "09_sunset_740",
	})
	# 推进第一段对白的收尾句，直到对白框关闭、头顶旁白播完。
	await _drive_dialogue_to_close()

	# 第一段对白结束：自由走动，A 提示落在国王身上
	var king: SurfaceProp = null
	for prop in planet.surface_props:
		if prop.kind == SurfaceProp.Kind.KING:
			king = prop
			break
	var prompt_deadline_msec := Time.get_ticks_msec() + 30000
	while not story.accepts_interact(king) and Time.get_ticks_msec() < prompt_deadline_msec:
		await process_frame
	for warmup_frame in 6:
		await process_frame
	await _shot("10_interact_prompt_on_king")

	story.try_handle_interact(king)

	await _drive_dialogue({
			"司法大臣！": "11_justice_minister",
			"你可以不时地判处它死刑，这样它的生命就取决于你的审判。": "12_rat_judgment",
			"我任命你为大使！": "13_ambassador",
	})
	# 推进“我任命你为大使！”之后的收尾，让对白关闭、剧情进入离星。
	await _drive_dialogue_to_close()

	# 离星：鸟群托起小王子，半空留下旅途感想
	await _await_overhead_shown("小王子在旅途中想：大人们真是太奇怪了。")
	await _shot("14_lift_halfway_strange_adults")

	# 黑场落幕
	var epilogue := scene.get_node("%Epilogue") as Label
	var epilogue_deadline_msec := Time.get_ticks_msec() + 40000
	while epilogue.text != "325。" and Time.get_ticks_msec() < epilogue_deadline_msec:
		await process_frame
	for hold_frame in 8:
		await process_frame
	await _shot("15_epilogue_325")

	print("CAPTURE_DONE")
	quit(0)


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	var image := game_viewport.get_texture().get_image()
	image.save_png("%s/%s.png" % [SHOT_DIR, shot_name])
	print("SHOT %s" % shot_name)


func _await_overhead_shown(display_text: String) -> void:
	var body := overhead.get_node("%Body") as Label
	var deadline_msec := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline_msec:
		if (
				overhead.visible
				and body.text == display_text
				and body.visible_characters >= body.get_total_character_count()
		):
			return
		await process_frame
	printerr("头顶叙事超时未出现：%s" % display_text)


func _await_dialogue_shown(display_text: String) -> void:
	var body := dialogue.get_node("%Body") as Label
	var deadline_msec := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline_msec:
		if (
				dialogue.is_open()
				and not dialogue.is_typing()
				and body.text == display_text
		):
			return
		await process_frame
	printerr("对白超时未出现：%s" % display_text)


## 持续推进对白直到对白框关闭（用于收尾句不在 beats 里的段落）。
func _drive_dialogue_to_close() -> void:
	var deadline_msec := Time.get_ticks_msec() + 120000
	while dialogue.is_open() and Time.get_ticks_msec() < deadline_msec:
		if not dialogue.is_typing():
			dialogue.mark_holding(true)
			await process_frame
			dialogue.mark_holding(false)
		await process_frame


## 自动推进整段对白；命中关键句先截图再继续。
func _drive_dialogue(beats: Dictionary) -> void:
	var body := dialogue.get_node("%Body") as Label
	var deadline_msec := Time.get_ticks_msec() + 300000
	while not beats.is_empty() and Time.get_ticks_msec() < deadline_msec:
		if dialogue.is_open() and not dialogue.is_typing():
			var shown_text := body.text
			if beats.has(shown_text):
				await _shot(beats[shown_text])
				beats.erase(shown_text)
			await process_frame
			await process_frame
			dialogue.mark_holding(true)
			await process_frame
			dialogue.mark_holding(false)
			await process_frame
		else:
			await process_frame
	if not beats.is_empty():
		printerr("对白驱动未走完，剩余：%s" % str(beats.keys()))
