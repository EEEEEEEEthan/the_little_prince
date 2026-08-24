class_name PlanetRunShell
extends Control
## 星球运行壳：256×224 视口、玩家、UI、输入与配乐。
## 视口拉伸、像素过滤等静态配置写在 planet_run_shell.tscn。

const META_OPENING_DAY_MUSIC := "opening_day_music"

@onready var game_viewport: SubViewport = $GameView/GameViewport
@onready var planet: Planet = $GameView/GameViewport/Planet
@onready var player: Player = $GameView/GameViewport/Player
@onready var dialogue: DialogueBox = %DialogueBox
@onready var interaction: Interaction = %Interaction


func _ready() -> void:
	_layout_world()
	planet.teleport_player(planet.spawn_angle)


func replace_planet(next_planet: Planet) -> void:
	var previous_planet := planet
	next_planet.name = "Planet"
	next_planet.unique_name_in_owner = true
	var planet_index := previous_planet.get_index()
	previous_planet.unique_name_in_owner = false
	previous_planet.name = "LeavingPlanet"
	game_viewport.add_child(next_planet)
	next_planet.owner = self
	game_viewport.move_child(next_planet, planet_index)
	planet = next_planet
	player.planet = next_planet
	(player.get_node("Scarf") as Scarf).planet = next_planet
	interaction.planet = next_planet
	game_viewport.remove_child(previous_planet)
	previous_planet.free()
	_layout_world()
	next_planet.teleport_player(next_planet.spawn_angle)
	player.modulate.a = 1.0
	%GameCamera.offset = Vector2.ZERO
	%Epilogue.text = ""
	%MigratoryFlock.visible = false
	%MigratoryFlock.set_process(false)


func _input(event: InputEvent) -> void:
	if not dialogue.is_open() or event.is_echo() or not event.is_action(&"interact"):
		return
	if event.is_pressed():
		dialogue.mark_holding(true)
		return
	var key := event as InputEventKey
	if key != null and key.physical_keycode != KEY_NONE and Input.is_physical_key_pressed(key.physical_keycode):
		return
	var joy_button := event as InputEventJoypadButton
	if joy_button != null and Input.is_joy_button_pressed(joy_button.device, joy_button.button_index):
		return
	dialogue.mark_holding(false)


func _layout_world() -> void:
	var viewport_size := Vector2(game_viewport.size)
	var apex_y := viewport_size.y * WorldConstants.APEX_Y_RATIO
	planet.global_position = Vector2(
		viewport_size.x * 0.5, apex_y + planet.radius
	)
	player.global_position = planet.apex_global_position()


static func present_standalone_planet(
		standalone_planet: Planet,
		run_shell_scene: PackedScene,
		day_music: AudioStream,
) -> void:
	var tree := standalone_planet.get_tree()
	var scene_root := standalone_planet.get_parent()
	if scene_root != tree.root:
		return
	var shell := run_shell_scene.instantiate() as PlanetRunShell
	if day_music != null:
		shell.get_node("Config").set_meta(META_OPENING_DAY_MUSIC, day_music)
	var viewport := shell.get_node("GameView/GameViewport") as SubViewport
	var camera := viewport.get_node("GameCamera")
	scene_root.remove_child(standalone_planet)
	standalone_planet.name = "Planet"
	standalone_planet.unique_name_in_owner = true
	viewport.add_child(standalone_planet)
	viewport.move_child(standalone_planet, camera.get_index() + 1)
	standalone_planet.owner = shell
	var story := standalone_planet.get_node("%Story") as PlanetStory
	story.auto_start = true
	story.start()
	scene_root.add_child(shell)
	tree.current_scene = shell
