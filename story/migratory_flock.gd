class_name MigratoryFlock
extends Node2D
## 候鸟：离星时从屏幕外飞到弧顶，再向上带走小王子。

const BIRD_COUNT := 7
const ARRIVE_SECONDS := 1.4
const WING_FRAME_MILLISECONDS := 140

@export var bird_texture: Texture2D

var _birds: Array[Sprite2D] = []


func _ready() -> void:
	visible = false
	set_process(false)
	for bird_index in BIRD_COUNT:
		var bird := Sprite2D.new()
		bird.texture = bird_texture
		bird.hframes = 2
		bird.texture_filter = TEXTURE_FILTER_NEAREST
		bird.z_index = 180
		add_child(bird)
		_birds.append(bird)


func arrive_from_offscreen(apex_global_position: Vector2) -> void:
	visible = true
	set_process(true)
	var viewport_rect := get_viewport().get_visible_rect()
	const offscreen_margin := 28.0
	for bird_index in _birds.size():
		var from_left := bird_index % 2 == 0
		var bird := _birds[bird_index]
		var spawn_x := (
				viewport_rect.position.x - offscreen_margin - float(bird_index) * 10.0
				if from_left
				else viewport_rect.end.x + offscreen_margin + float(bird_index) * 10.0
		)
		bird.global_position = Vector2(
				spawn_x,
				viewport_rect.position.y - offscreen_margin - float(bird_index) * 8.0
		)
		bird.flip_h = not from_left
	var gather_tween := create_tween().set_parallel(true)
	for bird_index in _birds.size():
		var scatter := Vector2.from_angle(float(bird_index) * 0.9) * 12.0
		gather_tween.tween_property(
				_birds[bird_index],
				"global_position",
				apex_global_position + scatter,
				ARRIVE_SECONDS
		)
	await gather_tween.finished


func lift(distance_pixels: float, duration_seconds: float) -> void:
	var lift_tween := create_tween().set_parallel(true)
	for bird in _birds:
		lift_tween.tween_property(
				bird,
				"global_position:y",
				bird.global_position.y - distance_pixels,
				duration_seconds
		)


func _process(_delta: float) -> void:
	var wing_frame := int(Time.get_ticks_msec() / WING_FRAME_MILLISECONDS) % 2
	for bird in _birds:
		bird.frame = wing_frame
