extends Node
## 星球作为当前场景运行时，套上可复用运行壳并启动该星故事。

const META_RUN_SHELL_SCENE := "run_shell_scene"
const META_STORY_SCRIPT := "story_script"
const META_DAY_MUSIC := "day_music"


func _ready() -> void:
	if owner.get_parent() != get_tree().root:
		return
	call_deferred(&"_present_with_run_shell")


func _present_with_run_shell() -> void:
	var story_script: Script = null
	if has_meta(META_STORY_SCRIPT):
		story_script = get_meta(META_STORY_SCRIPT) as Script
	var day_music: AudioStream = null
	if has_meta(META_DAY_MUSIC):
		day_music = get_meta(META_DAY_MUSIC) as AudioStream
	PlanetRunShell.present_standalone_planet(
			owner as Planet,
			get_meta(META_RUN_SHELL_SCENE) as PackedScene,
			story_script,
			day_music,
	)
