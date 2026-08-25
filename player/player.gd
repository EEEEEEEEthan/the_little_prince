class_name Player
extends Sprite2D
## 小王子：左右输入驱动星球旋转，自身钉在弧顶。
## 贴图为 idle+walk 横拼 spritesheet，按角速度切帧；左右用 flip_h。

@onready var planet: Planet = %Planet
@onready var interaction = %Interaction

var can_move_left: bool = true
var can_move_right: bool = true
var move_speed_scale: float = 1.0
var _anim_time: float = 0.0
var _was_moving: bool = false
var _last_walk_frame_index: int = -1

func _ready() -> void:
	hframes = WorldConstants.PLAYER_SPRITE_FRAME_COUNT
	vframes = 1
	scale = Vector2.ONE
	offset = Vector2(
		0.0,
		-float(WorldConstants.PLAYER_SPRITE_HEIGHT) * 0.5 + WorldConstants.PLAYER_VISUAL_Y_OFFSET
	)
	frame = 0

func _physics_process(delta: float) -> void:
	var direction := 0.0
	if not interaction.is_busy():
		if can_move_right:
			direction += Input.get_action_strength("move_right")
		if can_move_left:
			direction -= Input.get_action_strength("move_left")
		direction *= move_speed_scale
	planet.move_player(direction, delta)
	_update_animation(direction, delta)

func is_in_grass() -> bool:
	return has_overlapping_trigger_kind(WorldConstants.TriggerKind.GRASS)


func has_overlapping_trigger_kind(kind: WorldConstants.TriggerKind) -> bool:
	for area in %Footprint.get_overlapping_areas():
		if area.has_method("hosted_surface_prop") and area.kind == kind:
			return true
	return false


func find_nearest_interactable(should_accept: Callable = Callable()) -> SurfaceProp:
	var best: SurfaceProp = null
	var best_distance_squared := INF
	for area in %Footprint.get_overlapping_areas():
		if not area.has_method("hosted_surface_prop") or area.kind != WorldConstants.TriggerKind.INTERACT:
			continue
		var prop := area.hosted_surface_prop()
		if prop == null or not prop.is_interactable():
			continue
		if should_accept.is_valid() and not should_accept.call(prop):
			continue
		var distance_squared := global_position.distance_squared_to(area.global_position)
		if distance_squared <= best_distance_squared:
			best_distance_squared = distance_squared
			best = prop
	return best


func _update_animation(direction: float, delta: float) -> void:
	if absf(direction) > 0.01:
		flip_h = direction < 0.0
	var moving := planet.is_moving()
	if moving != _was_moving:
		_anim_time = 0.0
		_last_walk_frame_index = -1
		if not moving:
			%Footstep.stop()
		_was_moving = moving
	_anim_time += delta
	if moving:
		var walk_count := WorldConstants.PLAYER_WALK_FRAME_COUNT
		var walk_index := int(_anim_time * WorldConstants.PLAYER_WALK_FPS) % walk_count
		frame = WorldConstants.PLAYER_IDLE_FRAME_COUNT + walk_index
		if walk_index != _last_walk_frame_index:
			_last_walk_frame_index = walk_index
			if walk_index % 2 == 0 and not interaction.is_busy():
				%Footstep.play_step()
	else:
		var idle_count := WorldConstants.PLAYER_IDLE_FRAME_COUNT
		var idx := int(_anim_time * WorldConstants.PLAYER_IDLE_FPS) % idle_count
		frame = idx
