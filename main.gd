extends PlanetRunShell
## 旅程入口：开局 B612，离星后再换到国王的星球。

const META_KING_PLANET_SCENE := "king_planet_scene"

var travel_to_next_planet: bool = true


func _ready() -> void:
	super._ready()
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
	var next_planet := (
			$Config.get_meta(META_KING_PLANET_SCENE) as PackedScene
	).instantiate() as Planet
	replace_planet(next_planet)
	var king_story := %KingStory as KingStory
	king_story.planet = next_planet
	interaction.story = king_story
	%Music.play_king_day_loop()
	if start_story:
		king_story.start()
