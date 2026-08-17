class_name StackedProp
extends Node2D
## 多层切片地物的「数据描述」：位置、纹理、世界 pitch。
##
## 视觉不再画进 SubViewport（否则会被鱼眼在 r>1 裁掉）。
## 由 Main 下的 PropScreenOverlay 按 SphereProjection 逆映射叠到屏幕上，
## 沿屏幕径向 lean 堆叠，边缘高层可落到 r>1，从星球剪影凸出。
##
## 本节点挂在 props_root 下仅作数据容器；props_root.visible=false。

## 底→顶 的高度切片纹理
var layer_textures: Array[Texture2D] = []
## 相邻层的世界 pitch（贴图像素）；overlay 会换成屏幕像素间距
var pitch: float = 1.2
## 加到逻辑锚点上的微调（例如让根部贴地心）
var base_offset: Vector2 = Vector2.ZERO
## 环面世界像素边长
var world_pixel_size: float = float(WorldConstants.WORLD_PIXELS)
## 逻辑格子中心（世界像素，不含 base_offset）
var logical_center: Vector2 = Vector2.ZERO

## 由 WorldGenerator 调用：写入纹理与摆放参数（不创建可见精灵）
func configure(
	textures: Array[Texture2D],
	p_pitch: float,
	p_base_offset: Vector2,
	p_logical_center: Vector2,
	p_world: float = float(WorldConstants.WORLD_PIXELS)
) -> void:
	layer_textures = textures
	pitch = p_pitch
	base_offset = p_base_offset
	logical_center = p_logical_center
	world_pixel_size = p_world

## 地物锚点世界像素（含 base_offset）
func anchor_world() -> Vector2:
	return logical_center + base_offset

## 地物锚点归一化 UV（0~1），供 SphereProjection 使用
func world_uv() -> Vector2:
	var a := anchor_world()
	var w := maxf(world_pixel_size, 1.0)
	return Vector2(fposmod(a.x, w) / w, fposmod(a.y, w) / w)
