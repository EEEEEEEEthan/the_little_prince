extends SceneTree
## 无头回归：用真实输入走完已定稿星球的正常流程。

const REGRESSION_TIME_SCALE := 12.0
const FINALIZED_PLANET_IDS: PackedStringArray = ["B612"]
const STORY_PATH := "GameView/GameViewport/Planet/%Story"


func _init() -> void:
	Engine.time_scale = REGRESSION_TIME_SCALE
	call_deferred(&"_begin")


func _begin() -> void:
	var requested_planet_ids := _requested_planet_ids()
	if requested_planet_ids.is_empty():
		return
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var packed_scene := load("res://journey/main.tscn") as PackedScene
	var shell := packed_scene.instantiate()
	shell.travel_to_next_planet = false
	var story := shell.get_node(STORY_PATH) as PlanetStory
	story.departed.connect(_on_planet_departed.bind(requested_planet_ids), CONNECT_ONE_SHOT)
	root.add_child(shell)
	var driver := RegressionDriver.new()
	driver.shell = shell
	shell.add_child(driver)
	print("[regression] 开始 %s" % ", ".join(requested_planet_ids))


func _requested_planet_ids() -> PackedStringArray:
	var planet_id := ""
	var user_args := OS.get_cmdline_user_args()
	for argument_index in user_args.size():
		if user_args[argument_index] != "--planet":
			continue
		if argument_index + 1 >= user_args.size():
			push_error("[regression] --planet 需要星球名")
			quit(1)
			return PackedStringArray()
		planet_id = user_args[argument_index + 1]
		break
	if planet_id.is_empty():
		return FINALIZED_PLANET_IDS.duplicate()
	for finalized_planet_id in FINALIZED_PLANET_IDS:
		if finalized_planet_id == planet_id:
			return PackedStringArray([planet_id])
	push_error("[regression] 未知或未定稿星球：%s" % planet_id)
	quit(1)
	return PackedStringArray()


func _on_planet_departed(requested_planet_ids: PackedStringArray) -> void:
	print("[regression] 完成 %s" % ", ".join(requested_planet_ids))
	print("[regression] 通过")
	quit(0)


class RegressionDriver extends Node:
	var shell: Node
	var _move_left_pressed: bool = false
	var _move_right_pressed: bool = false
	var _interact_pressed: bool = false
	var _should_release_interact: bool = false

	func _ready() -> void:
		process_priority = -128


	func _process(_delta: float) -> void:
		var story := shell.get_node("GameView/GameViewport/Planet/%Story") as PlanetStory
		var player := shell.get_node("%Player") as Player
		var planet := shell.get_node("%Planet") as Planet
		var dialogue := story.dialogue
		if _should_release_interact:
			_set_action(&"interact", false)
			_should_release_interact = false
			return
		if dialogue.is_open():
			_set_action(&"move_left", false)
			_set_action(&"move_right", false)
			if dialogue.is_typing():
				_set_action(&"interact", true)
			elif _interact_pressed:
				_set_action(&"interact", false)
			else:
				_set_action(&"interact", true)
				_should_release_interact = true
			return
		if story.is_blocking_input:
			_release_all()
			return
		var focused_prop := planet.find_nearest_interactable(story.accepts_interact)
		if focused_prop != null:
			_set_action(&"move_left", false)
			_set_action(&"move_right", false)
			if story.interact_hold_seconds(focused_prop) > 0.0:
				_set_action(&"interact", true)
			elif _interact_pressed:
				_set_action(&"interact", false)
			else:
				_set_action(&"interact", true)
				_should_release_interact = true
			return
		_set_action(&"interact", false)
		var walk_left := false
		var walk_right := false
		var target_prop := _nearest_accepted_prop(planet, story)
		if target_prop != null:
			var signed_offset := angle_difference(planet.player_angle, target_prop.rotation)
			walk_right = signed_offset > 0.0 and player.can_move_right
			walk_left = signed_offset < 0.0 and player.can_move_left
		elif player.can_move_right:
			walk_right = true
		_set_action(&"move_left", walk_left)
		_set_action(&"move_right", walk_right)


	func _nearest_accepted_prop(planet: Planet, story: PlanetStory) -> SurfaceProp:
		var nearest_prop: SurfaceProp = null
		var nearest_offset := INF
		for prop in planet.surface_props:
			if not story.accepts_interact(prop):
				continue
			var offset := absf(angle_difference(planet.player_angle, prop.rotation))
			if offset <= nearest_offset:
				nearest_offset = offset
				nearest_prop = prop
		return nearest_prop


	func _release_all() -> void:
		_set_action(&"move_left", false)
		_set_action(&"move_right", false)
		_set_action(&"interact", false)


	func _set_action(action: StringName, pressed: bool) -> void:
		var currently_pressed := false
		match action:
			&"move_left":
				currently_pressed = _move_left_pressed
			&"move_right":
				currently_pressed = _move_right_pressed
			&"interact":
				currently_pressed = _interact_pressed
		if currently_pressed == pressed:
			return
		match action:
			&"move_left":
				_move_left_pressed = pressed
			&"move_right":
				_move_right_pressed = pressed
			&"interact":
				_interact_pressed = pressed
		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)


	func _exit_tree() -> void:
		_release_all()
