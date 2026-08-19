class_name Scarf
extends Node2D
## 小王子围巾：在玩家本地空间做 Verlet 绳。
## 人钉在弧顶、行走靠星球反转，引擎刚体没有表观惯性，所以不用物理体。
## 模拟每物理帧更新，显示按固定帧率取整，做成像素抽帧。

const POINT_COUNT: int = 6
const SEGMENT_LENGTH: float = 1.45
const GRAVITY: float = 200.0
const DAMPING: float = 0.88
const WIND_PER_WALK_SPEED: float = 18.0
const IDLE_SWAY: float = 52.0
const CONSTRAINT_ITERATIONS: int = 5
const DISPLAY_FPS: float = 8.0
const NECK_SIDE_OFFSET: float = 2.0
const NECK_LOCAL_Y: float = -9.0
const MIN_LOCAL_Y: float = -15.0
const MAX_LOCAL_Y: float = 0.0
const COLOR := Color8(242, 198, 63)
const SHADOW_COLOR := Color8(219, 140, 35)

@onready var planet: Planet = %Planet
@onready var player: Player = %Player

var simulated_positions: PackedVector2Array
var previous_positions: PackedVector2Array
var display_positions: PackedVector2Array
var _display_accumulator: float = 0.0


func _ready() -> void:
	var neck := _neck_local_position()
	var hang_direction := Vector2(-_facing_sign(), 1.2).normalized()
	simulated_positions.resize(POINT_COUNT)
	previous_positions.resize(POINT_COUNT)
	display_positions.resize(POINT_COUNT)
	for point_index in POINT_COUNT:
		var point := neck + hang_direction * SEGMENT_LENGTH * float(point_index)
		simulated_positions[point_index] = point
		previous_positions[point_index] = point
	for _settle_step in 24:
		_simulate(1.0 / 60.0)
	_capture_display()


func _physics_process(delta: float) -> void:
	_simulate(delta)
	_display_accumulator += delta
	var display_interval := 1.0 / DISPLAY_FPS
	if _display_accumulator >= display_interval:
		_display_accumulator = fmod(_display_accumulator, display_interval)
		_capture_display()


func _draw() -> void:
	for point_index in range(display_positions.size() - 1):
		var thickness := 2 if point_index < 2 else 1
		_draw_pixel_line(
				Vector2i(display_positions[point_index]),
				Vector2i(display_positions[point_index + 1]),
				thickness
		)


func _simulate(delta: float) -> void:
	_pin_neck()
	var walk_speed := planet.angular_velocity * WorldConstants.PLANET_RADIUS
	var motion_weight := clampf(absf(walk_speed) / (WorldConstants.PLAYER_SPEED * 0.25), 0.0, 1.0)
	var wind_x := lerpf(
			-_facing_sign() * IDLE_SWAY,
			-walk_speed * WIND_PER_WALK_SPEED,
			motion_weight
	)
	var acceleration := Vector2(wind_x, GRAVITY)
	var delta_squared := delta * delta
	for point_index in range(1, POINT_COUNT):
		var current_position := simulated_positions[point_index]
		var previous_position := previous_positions[point_index]
		var next_position := (
				current_position
				+ (current_position - previous_position) * DAMPING
				+ acceleration * delta_squared
		)
		previous_positions[point_index] = current_position
		simulated_positions[point_index] = next_position
	for _constraint_pass in CONSTRAINT_ITERATIONS:
		for point_index in range(1, POINT_COUNT):
			var from_position := simulated_positions[point_index - 1]
			var to_position := simulated_positions[point_index]
			var segment_offset := to_position - from_position
			var distance := segment_offset.length()
			if distance < 0.001:
				segment_offset = Vector2(0.0, 1.0)
				distance = 1.0
			var correction := segment_offset * (1.0 - SEGMENT_LENGTH / distance)
			if point_index == 1:
				simulated_positions[point_index] = to_position - correction
			else:
				simulated_positions[point_index - 1] = from_position + correction * 0.5
				simulated_positions[point_index] = to_position - correction * 0.5
		_pin_neck()
		for point_index in range(1, POINT_COUNT):
			var clamped := simulated_positions[point_index]
			clamped.y = clampf(clamped.y, MIN_LOCAL_Y, MAX_LOCAL_Y)
			simulated_positions[point_index] = clamped


func _capture_display() -> void:
	display_positions.resize(POINT_COUNT)
	for point_index in POINT_COUNT:
		display_positions[point_index] = simulated_positions[point_index].round()
	queue_redraw()


func _pin_neck() -> void:
	var neck := _neck_local_position()
	simulated_positions[0] = neck
	previous_positions[0] = neck


func _neck_local_position() -> Vector2:
	var walk_index := player.frame - WorldConstants.PLAYER_IDLE_FRAME_COUNT
	var body_bob := 1.0 if walk_index >= 0 and walk_index % 2 == 0 else 0.0
	return Vector2(NECK_SIDE_OFFSET * -_facing_sign(), NECK_LOCAL_Y + body_bob)


func _facing_sign() -> float:
	return -1.0 if player.flip_h else 1.0


func _draw_pixel_line(from_pixel: Vector2i, to_pixel: Vector2i, thickness: int) -> void:
	var delta_x := absi(to_pixel.x - from_pixel.x)
	var delta_y := absi(to_pixel.y - from_pixel.y)
	var step_x := 1 if from_pixel.x < to_pixel.x else -1
	var step_y := 1 if from_pixel.y < to_pixel.y else -1
	var error := delta_x - delta_y
	var pixel := from_pixel
	while true:
		draw_rect(Rect2(Vector2(pixel) + Vector2(0.0, 1.0), Vector2.ONE), SHADOW_COLOR)
		draw_rect(Rect2(Vector2(pixel), Vector2(thickness, 1.0)), COLOR)
		if pixel == to_pixel:
			break
		var doubled_error := error * 2
		if doubled_error > -delta_y:
			error -= delta_y
			pixel.x += step_x
		if doubled_error < delta_x:
			error += delta_x
			pixel.y += step_y
