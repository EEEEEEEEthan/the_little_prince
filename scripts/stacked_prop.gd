class_name StackedProp
extends Node2D
## 多层切片地物：沿「玩家→地物」环面最短方向堆叠，形成伪 3D 凸出。
##
## 原理（配合 sphere_fisheye 球心=玩家）：
## - 本地 -Y（精灵「头」）对齐环面最短向量 outward（地物相对玩家）
## - 球视图下方时 outward≈+Y，精灵头朝下；边缘时沿径向偏移凸出
## - 靠近玩家时 |delta| 极小，fallback 为世界朝上，看起来近乎直立
##
## 结构：本节点下 3×3 环绕副本（各一份层叠），seam 与旧 Sprite wrap 一致。

## 底→顶 的高度切片纹理
var layer_textures: Array[Texture2D] = []
## 相邻层沿 outward 的间距（像素）
var pitch: float = 1.2
## 加到逻辑锚点上的微调（例如让根部贴地心）
var base_offset: Vector2 = Vector2.ZERO
## 环面世界像素边长（与 Player.world_pixel_size 一致）
var world_pixel_size: float = float(WorldConstants.WORLD_PIXELS)

## 逻辑锚点（主副本，不含 wrap 偏移；含 base_offset 之前的格子中心）
var _logical_center: Vector2 = Vector2.ZERO
## 9 个环绕副本根节点（各含一层层 Sprite2D）
var _wrap_roots: Array[Node2D] = []
## 每个副本的层精灵：_wrap_layers[wrap_i][layer_i]
var _wrap_layers: Array = []
var _player: Node2D = null
var _built: bool = false

## 由 WorldGenerator 调用：写入纹理与摆放参数并搭建 3×3 层叠
func configure(
	textures: Array[Texture2D],
	p_pitch: float,
	p_base_offset: Vector2,
	logical_center: Vector2,
	p_world: float = float(WorldConstants.WORLD_PIXELS)
) -> void:
	layer_textures = textures
	pitch = p_pitch
	base_offset = p_base_offset
	_logical_center = logical_center
	world_pixel_size = p_world
	_rebuild_wraps()

func _ready() -> void:
	# 若尚未 configure（例如场景里手摆），在就绪时按当前属性搭建
	if not _built and not layer_textures.is_empty():
		_rebuild_wraps()
	set_process(true)

func _process(_delta: float) -> void:
	if not _built:
		return
	var player := _resolve_player()
	if player == null:
		return
	update_toward(player.global_position)

## 外部也可每帧调用：按玩家世界坐标刷新全部环绕副本的朝向与层偏移
func update_toward(player_world_pos: Vector2) -> void:
	if not _built:
		return
	var world := world_pixel_size
	# 玩家逻辑坐标落在 [0, world) 内，便于找最近镜像
	var player_base := Vector2(
		fposmod(player_world_pos.x, world),
		fposmod(player_world_pos.y, world)
	)
	var wi := 0
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			var root: Node2D = _wrap_roots[wi]
			var anchor: Vector2 = _logical_center + base_offset + Vector2(float(ox) * world, float(oy) * world)
			root.global_position = anchor

			var delta := _torus_delta_to_nearest_player(anchor, player_base, world)
			var outward: Vector2
			if delta.length() < WorldConstants.STACK_OUTWARD_EPSILON:
				outward = Vector2(0, -1)
			else:
				outward = delta.normalized()

			# 本地 -Y 对齐 outward：Sprite2D 默认「上」是 -Y
			root.rotation = outward.angle() + PI * 0.5

			var layers: Array = _wrap_layers[wi]
			for i in layers.size():
				var sprite: Sprite2D = layers[i]
				# 父节点已旋转，本地 -Y 即世界 outward
				sprite.position = Vector2(0, -pitch * float(i))
				sprite.z_index = i
			wi += 1

## ---------- 搭建 ----------

func _rebuild_wraps() -> void:
	for child in get_children():
		child.queue_free()
	_wrap_roots.clear()
	_wrap_layers.clear()

	if layer_textures.is_empty():
		_built = false
		return

	var world := world_pixel_size
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			var root := Node2D.new()
			root.name = "Wrap_%d_%d" % [ox, oy]
			root.position = _logical_center + base_offset + Vector2(float(ox) * world, float(oy) * world)
			add_child(root)
			_wrap_roots.append(root)

			var layers: Array[Sprite2D] = []
			for i in layer_textures.size():
				var sprite := Sprite2D.new()
				sprite.texture = layer_textures[i]
				sprite.centered = true
				sprite.position = Vector2(0, -pitch * float(i))
				sprite.z_index = i
				root.add_child(sprite)
				layers.append(sprite)
			_wrap_layers.append(layers)

	_built = true
	# 初始朝上，等第一帧 _process 再对齐玩家
	update_toward(Vector2(_logical_center.x, _logical_center.y + world * 0.25))

## ---------- 环面几何 ----------

## 地物锚点相对「最近玩家镜像」的位移（prop - player），即环面最短向量
static func _torus_delta_to_nearest_player(anchor: Vector2, player_base: Vector2, world: float) -> Vector2:
	var best := Vector2.ZERO
	var best_len2 := INF
	for px in range(-1, 2):
		for py in range(-1, 2):
			var player_img := player_base + Vector2(float(px) * world, float(py) * world)
			var d := anchor - player_img
			var len2 := d.length_squared()
			if len2 < best_len2:
				best_len2 = len2
				best = d
	return best

## 与静态方法等价的实例封装，便于测试调用
func torus_delta(anchor: Vector2, player_world_pos: Vector2) -> Vector2:
	var world := world_pixel_size
	var player_base := Vector2(fposmod(player_world_pos.x, world), fposmod(player_world_pos.y, world))
	return _torus_delta_to_nearest_player(anchor, player_base, world)

func _resolve_player() -> Node2D:
	if is_instance_valid(_player):
		return _player
	# Props 与 Player 同属 PlanetWorld
	var props := get_parent()
	if props == null:
		return null
	var world_root := props.get_parent()
	if world_root == null:
		return null
	_player = world_root.get_node_or_null("Player") as Node2D
	return _player
