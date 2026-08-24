extends "res://planet/planet_run_shell.gd"
## 旅程入口：开局 B612，离星后国王，再酒鬼，再商人，再点灯人，再地理学家。

const META_KING_PLANET_SCENE := "king_planet_scene"
const META_DRUNKARD_PLANET_SCENE := "drunkard_planet_scene"
const META_MERCHANT_PLANET_SCENE := "merchant_planet_scene"
const META_LAMPLIGHTER_PLANET_SCENE := "lamplighter_planet_scene"
const META_GEOGRAPHER_PLANET_SCENE := "geographer_planet_scene"

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
	_swap_journey_planet(
			META_KING_PLANET_SCENE,
			%KingStory as KingStory,
			%Music.play_king_day_loop,
			start_story
	)
	if start_story:
		(%KingStory as KingStory).departed.connect(
				travel_to_drunkard_planet,
				CONNECT_ONE_SHOT | CONNECT_DEFERRED
		)


func travel_to_drunkard_planet(start_story := true) -> void:
	if not travel_to_next_planet:
		return
	_swap_journey_planet(
			META_DRUNKARD_PLANET_SCENE,
			%DrunkardStory as DrunkardStory,
			%Music.play_drunkard_day_loop,
			start_story
	)
	if start_story:
		(%DrunkardStory as DrunkardStory).departed.connect(
				travel_to_merchant_planet,
				CONNECT_ONE_SHOT | CONNECT_DEFERRED
		)


func travel_to_merchant_planet(start_story := true) -> void:
	if not travel_to_next_planet:
		return
	_swap_journey_planet(
			META_MERCHANT_PLANET_SCENE,
			%MerchantStory as MerchantStory,
			%Music.play_merchant_day_loop,
			start_story
	)
	if start_story:
		(%MerchantStory as MerchantStory).departed.connect(
				travel_to_lamplighter_planet,
				CONNECT_ONE_SHOT | CONNECT_DEFERRED
		)


func travel_to_lamplighter_planet(start_story := true) -> void:
	if not travel_to_next_planet:
		return
	_swap_journey_planet(
			META_LAMPLIGHTER_PLANET_SCENE,
			%LamplighterStory as LamplighterStory,
			%Music.play_lamplighter_day_loop,
			start_story
	)
	if start_story:
		(%LamplighterStory as LamplighterStory).departed.connect(
				travel_to_geographer_planet,
				CONNECT_ONE_SHOT | CONNECT_DEFERRED
		)


func travel_to_geographer_planet(start_story := true) -> void:
	if not travel_to_next_planet:
		return
	travel_to_next_planet = false
	_swap_journey_planet(
			META_GEOGRAPHER_PLANET_SCENE,
			%GeographerStory as GeographerStory,
			%Music.play_geographer_day_loop,
			start_story
	)


func _swap_journey_planet(
		planet_scene_meta_name: String,
		next_story: PlanetStory,
		play_day_music: Callable,
		start_story: bool
) -> void:
	var previous_story := interaction.story as PlanetStory
	previous_story.is_active = false
	previous_story.set_process(false)
	var next_planet := (
			$Config.get_meta(planet_scene_meta_name) as PackedScene
	).instantiate() as Planet
	replace_planet(next_planet)
	next_story.planet = next_planet
	interaction.story = next_story
	play_day_music.call()
	if start_story:
		next_story.start()
