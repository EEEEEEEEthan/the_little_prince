class_name Player
extends CharacterBody2D
## 小王子本人。使用方向键 / WASD 在伪星球平面网格上移动，
## 走出地图任意一边会从对边环绕出现（左右、上下都首尾相连），
## 这正是让平面地图能够被 shader 包裹成一颗「球」的关键前提。
##
## 视觉上通过 3×3 幽灵精灵保证：当小王子靠近地图边缘时，
## SubViewport 纹理的对侧仍能画出他伸出边界的部分，球面无缝。

## 世界像素边长（由 main.gd 在场景搭建完成后写入，默认值与常量保持一致）
var world_pixel_size: float = float(WorldConstants.WORLD_PIXELS)

var _sprite: Sprite2D
## 环绕幽灵：8 个偏移副本，跟随本体同步移动
var _ghosts: Array[Sprite2D] = []

func _ready() -> void:
	var tex := PixelArt.make_player_sprite(14, 20)
	_sprite = Sprite2D.new()
	_sprite.name = "小王子精灵"
	_sprite.texture = tex
	_sprite.centered = true
	_sprite.z_index = 10
	add_child(_sprite)

	# 幽灵挂在 PlanetWorld 下，避免作为 CharacterBody2D 子节点被重复变换
	var ghost_root := Node2D.new()
	ghost_root.name = "小王子环绕幽灵"
	ghost_root.z_index = 10
	get_parent().add_child(ghost_root)

	var world := world_pixel_size
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			var ghost := Sprite2D.new()
			ghost.texture = tex
			ghost.centered = true
			ghost.z_index = 10
			ghost.position = global_position + Vector2(float(ox) * world, float(oy) * world)
			ghost_root.add_child(ghost)
			_ghosts.append(ghost)

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * WorldConstants.PLAYER_SPEED
	move_and_slide()
	_wrap_around()
	_sync_ghosts()

## 环绕（toroidal wrap）：X、Y 分别对世界像素边长取模，
## 使地图在逻辑上首尾相连，视觉上则由 shader 呈现为完整球面。
func _wrap_around() -> void:
	global_position.x = fposmod(global_position.x, world_pixel_size)
	global_position.y = fposmod(global_position.y, world_pixel_size)

func _sync_ghosts() -> void:
	if _ghosts.is_empty():
		return
	var world := world_pixel_size
	var i := 0
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			_ghosts[i].global_position = global_position + Vector2(float(ox) * world, float(oy) * world)
			i += 1

## 玩家在整张地图上的归一化坐标（0~1），供球面 shader 用作采样中心
func normalized_uv() -> Vector2:
	return Vector2(
		fposmod(global_position.x, world_pixel_size) / world_pixel_size,
		fposmod(global_position.y, world_pixel_size) / world_pixel_size
	)
