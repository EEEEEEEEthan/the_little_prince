class_name MigratoryFlock
extends Node2D
## 候鸟：先在星球外圈盘旋，离星时收到弧顶再向上带走小王子。

const BIRD_COUNT := 7
const ORBIT_RADIUS := 118.0
const ORBIT_ANGULAR_SPEED := 0.42
const WING_FRAME_MILLISECONDS := 140

@onready var planet: Planet = %Planet

var _orbit_angle: float = 0.0
var _is_orbiting: bool = false
var _birds: Array[Sprite2D] = []


func _ready() -> void:
	visible = false
	set_process(false)
	var bird_texture := preload("res://planet/migratory_bird.png")
	for bird_index in BIRD_COUNT:
		var bird := Sprite2D.new()
		bird.texture = bird_texture
		bird.hframes = 2
		bird.texture_filter = TEXTURE_FILTER_NEAREST
		bird.z_index = 180
		add_child(bird)
		_birds.append(bird)


func appear() -> void:
	visible = true
	_is_orbiting = true
	set_process(true)
	_place_on_orbit()


func gather_to_apex(apex_global_position: Vector2) -> void:
	_is_orbiting = false
	var gather_tween := create_tween().set_parallel(true)
	for bird_index in _birds.size():
		var scatter := Vector2.from_angle(float(bird_index) * 0.9) * 12.0
		gather_tween.tween_property(
				_birds[bird_index],
				"global_position",
				apex_global_position + scatter,
				1.5
		)
	await gather_tween.finished


func lift(distance_pixels: float, duration_seconds: float) -> void:
	_is_orbiting = false
	var lift_tween := create_tween().set_parallel(true)
	for bird in _birds:
		lift_tween.tween_property(
				bird,
				"global_position:y",
				bird.global_position.y - distance_pixels,
				duration_seconds
		)


func _process(delta: float) -> void:
	var wing_frame := int(Time.get_ticks_msec() / WING_FRAME_MILLISECONDS) % 2
	for bird in _birds:
		bird.frame = wing_frame
	if not _is_orbiting:
		return
	_orbit_angle = fposmod(_orbit_angle + ORBIT_ANGULAR_SPEED * delta, TAU)
	_place_on_orbit()


func _place_on_orbit() -> void:
	var planet_center := planet.global_position
	for bird_index in _birds.size():
		var orbital_angle := (
				_orbit_angle + TAU * float(bird_index) / float(_birds.size())
		)
		var orbit_radius := ORBIT_RADIUS + sin(orbital_angle * 3.0) * 8.0
		var bird := _birds[bird_index]
		bird.global_position = (
				planet_center
				+ Vector2(sin(orbital_angle), -cos(orbital_angle)) * orbit_radius
		)
		bird.flip_h = cos(orbital_angle) < 0.0
