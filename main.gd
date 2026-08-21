extends Control
## 入口总控：把星球与玩家按固定 256×224 视口布局并开局。
## 视口拉伸、像素过滤等静态配置均已写在 main.tscn。
## 开局 B612，离星后再换到国王的星球。

const META_KING_PLANET_SCENE := "king_planet_scene"

@onready var game_viewport: SubViewport = $GameView/GameViewport
@onready var planet: Planet = $GameView/GameViewport/Planet
@onready var player: Player = $GameView/GameViewport/Player
@onready var dialogue: DialogueBox = %DialogueBox
@onready var interaction: Interaction = %Interaction

var travel_to_next_planet: bool = true


func _ready() -> void:
	_layout_world()
	planet.teleport_player(planet.spawn_angle)
	(%Story as PlanetStory).departed.connect(
			travel_to_king_planet,
			CONNECT_ONE_SHOT | CONNECT_DEFERRED
	)


func travel_to_king_planet(start_story := true) -> void:
	if not travel_to_next_planet:
		return
	travel_to_next_planet = false
	var previous_story := %Story as PlanetStory
	previous_story.is_active = false
	previous_story.set_process(false)
	var previous_planet := planet
	var next_planet := (
			$Config.get_meta(META_KING_PLANET_SCENE) as PackedScene
	).instantiate() as Planet
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
	var king_story := %KingStory as KingStory
	king_story.planet = next_planet
	interaction.story = king_story
	game_viewport.remove_child(previous_planet)
	previous_planet.free()
	_layout_world()
	next_planet.teleport_player(next_planet.spawn_angle)
	player.modulate.a = 1.0
	%GameCamera.offset = Vector2.ZERO
	%Epilogue.text = ""
	%MigratoryFlock.visible = false
	%MigratoryFlock.set_process(false)
	%Music.play_king_day_loop()
	if start_story:
		king_story.start()


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
