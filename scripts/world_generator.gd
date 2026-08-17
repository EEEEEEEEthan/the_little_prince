class_name WorldGenerator
extends Node2D
## 负责搭建整颗伪星球的「地面真相」：
## 1) 生成 32×32 的 TileMapLayer 地表（沙地/岩地，每格 16×16 像素）
## 2) 摆放 3 座火山、1 朵玫瑰、若干猴面包树（均为 StackedProp 伪 3D）
## 3) 计算玩家出生点
##
## 本节点运行在被隐藏渲染的 SubViewport 内部，其渲染结果会被
## sphere_fisheye.gdshader 采样为「整颗星球」的贴图源。
##
## 地物采用 StackedProp：3×3 环绕副本 + 沿玩家径向的多层切片堆叠，
## 球视图下方头朝下、边缘凸出；跨边界时 seam 仍不可见。

@onready var ground: TileMapLayer = $Ground
@onready var props_root: Node2D = $Props

const SAND_ATLAS_X := 0
const ROCK_ATLAS_X := 1

var volcano_tiles: Array[Vector2i] = []
var baobab_tiles: Array[Vector2i] = []
var rose_tile: Vector2i = Vector2i.ZERO
var spawn_tile: Vector2i = Vector2i.ZERO

## 已生成的 StackedProp 引用，便于测试 / 外部批量更新
var stacked_props: Array[StackedProp] = []

## 记录被地物占用的格子，避免火山/玫瑰/猴面包树互相重叠
var _occupied: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = WorldConstants.WORLD_SEED
	_build_tileset()
	_paint_terrain()
	_place_rose()
	_place_volcanoes()
	_place_baobabs()
	_choose_spawn_tile()

## ---------- 地表 ----------

func _build_tileset() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(WorldConstants.TILE_SIZE, WorldConstants.TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = _build_terrain_atlas()
	atlas.texture_region_size = Vector2i(WorldConstants.TILE_SIZE, WorldConstants.TILE_SIZE)
	atlas.create_tile(Vector2i(SAND_ATLAS_X, 0))
	atlas.create_tile(Vector2i(ROCK_ATLAS_X, 0))

	tile_set.add_source(atlas, 0)
	ground.tile_set = tile_set

## 把沙地/岩地两张小贴图拼进同一张图集纹理，供 TileSetAtlasSource 使用
func _build_terrain_atlas() -> ImageTexture:
	var ts := WorldConstants.TILE_SIZE
	var atlas_img := Image.create(ts * 2, ts, false, Image.FORMAT_RGBA8)
	atlas_img.blit_rect(
		PixelArt.make_sand_tile(ts).get_image(),
		Rect2i(Vector2i.ZERO, Vector2i(ts, ts)),
		Vector2i(SAND_ATLAS_X * ts, 0)
	)
	atlas_img.blit_rect(
		PixelArt.make_rock_tile(ts).get_image(),
		Rect2i(Vector2i.ZERO, Vector2i(ts, ts)),
		Vector2i(ROCK_ATLAS_X * ts, 0)
	)
	return ImageTexture.create_from_image(atlas_img)

## 用 FastNoiseLite 生成自然一点的沙地/岩地分布（可复现，种子固定）
func _paint_terrain() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = WorldConstants.WORLD_SEED
	noise.frequency = 0.09
	for y in WorldConstants.MAP_TILES:
		for x in WorldConstants.MAP_TILES:
			var n: float = noise.get_noise_2d(float(x), float(y))
			var atlas_x := ROCK_ATLAS_X if n > 0.12 else SAND_ATLAS_X
			ground.set_cell(Vector2i(x, y), 0, Vector2i(atlas_x, 0))

## ---------- 地物摆放 ----------

## 玫瑰唯一且固定放在星球「正中央」——象征小王子星球上那朵独一无二的玫瑰
func _place_rose() -> void:
	rose_tile = Vector2i(WorldConstants.MAP_TILES / 2, WorldConstants.MAP_TILES / 2)
	_occupied[rose_tile] = true
	_spawn_stacked_prop(
		rose_tile,
		PixelArt.make_rose_layers(18, WorldConstants.ROSE_LAYER_COUNT),
		WorldConstants.ROSE_PITCH,
		Vector2(0, -2)
	)

## 3 座火山彼此保持环面最小距离，视觉上分散在星球各处
func _place_volcanoes() -> void:
	var margin := 3
	var attempts := 0
	while volcano_tiles.size() < WorldConstants.VOLCANO_COUNT and attempts < 2000:
		attempts += 1
		var t := Vector2i(
			_rng.randi_range(margin, WorldConstants.MAP_TILES - margin - 1),
			_rng.randi_range(margin, WorldConstants.MAP_TILES - margin - 1)
		)
		if _occupied.has(t):
			continue
		var far_enough := true
		for other in volcano_tiles:
			if _torus_distance(t, other) < WorldConstants.VOLCANO_MIN_DISTANCE:
				far_enough = false
				break
		if not far_enough:
			continue
		volcano_tiles.append(t)
		_occupied[t] = true
		_spawn_stacked_prop(
			t,
			PixelArt.make_volcano_layers(36, WorldConstants.VOLCANO_LAYER_COUNT),
			WorldConstants.VOLCANO_PITCH,
			Vector2(0, -6)
		)

## 猴面包树数量多，随机散布但避免彼此紧贴或压在火山/玫瑰上
func _place_baobabs() -> void:
	var attempts := 0
	while baobab_tiles.size() < WorldConstants.BAOBAB_COUNT and attempts < 5000:
		attempts += 1
		var t := Vector2i(
			_rng.randi_range(0, WorldConstants.MAP_TILES - 1),
			_rng.randi_range(0, WorldConstants.MAP_TILES - 1)
		)
		if _occupied.has(t):
			continue
		var too_close := false
		for other in baobab_tiles:
			if _torus_distance(t, other) < WorldConstants.BAOBAB_MIN_DISTANCE:
				too_close = true
				break
		if too_close:
			continue
		baobab_tiles.append(t)
		_occupied[t] = true
		_spawn_stacked_prop(
			t,
			PixelArt.make_baobab_layers(28, WorldConstants.BAOBAB_LAYER_COUNT),
			WorldConstants.BAOBAB_PITCH,
			Vector2(0, -4)
		)

## 出生点选在玫瑰旁边的空地——小王子每天都会照看他的玫瑰
func _choose_spawn_tile() -> void:
	var ring: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
	]
	for offset in ring:
		var t := _wrap_tile(rose_tile + offset)
		if not _occupied.has(t):
			spawn_tile = t
			return
	spawn_tile = _wrap_tile(rose_tile + Vector2i(3, 0))

## ---------- 工具函数 ----------

func _wrap_tile(t: Vector2i) -> Vector2i:
	return Vector2i(posmod(t.x, WorldConstants.MAP_TILES), posmod(t.y, WorldConstants.MAP_TILES))

## 环面（首尾相连）距离：地图边缘会「绕回」，因此不能直接用普通欧氏距离
func _torus_distance(a: Vector2i, b: Vector2i) -> float:
	var n := WorldConstants.MAP_TILES
	var dx: int = absi(a.x - b.x)
	dx = mini(dx, n - dx)
	var dy: int = absi(a.y - b.y)
	dy = mini(dy, n - dy)
	return Vector2(float(dx), float(dy)).length()

func _tile_center(tile: Vector2i) -> Vector2:
	var ts := float(WorldConstants.TILE_SIZE)
	return Vector2(float(tile.x) * ts + ts * 0.5, float(tile.y) * ts + ts * 0.5)

## 在逻辑格子上生成一个 StackedProp（内部自带 3×3 环绕 + 径向层叠）
func _spawn_stacked_prop(
	tile: Vector2i,
	textures: Array[Texture2D],
	pitch: float,
	extra_offset: Vector2
) -> StackedProp:
	var prop := StackedProp.new()
	prop.name = "StackedProp_%d_%d" % [tile.x, tile.y]
	props_root.add_child(prop)
	prop.configure(
		textures,
		pitch,
		extra_offset,
		_tile_center(tile),
		float(WorldConstants.WORLD_PIXELS)
	)
	stacked_props.append(prop)
	return prop

## 供 main.gd / Player 使用：出生点的世界坐标（像素）
func spawn_world_position() -> Vector2:
	return _tile_center(spawn_tile)
