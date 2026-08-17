class_name WorldConstants
extends RefCounted
## 全局世界常量：小王子伪星球的地图/资源规格集中管理，避免魔法数字散落各处。

## 单个地表格子的像素边长（每格 16×16 像素）
const TILE_SIZE: int = 16
## 地图逻辑网格边长（32×32 格，构成一张可首尾相连的环面地图）
const MAP_TILES: int = 32
## 整张地图渲染成纹理后的像素边长（32×16 = 512）
const WORLD_PIXELS: int = TILE_SIZE * MAP_TILES

## 地物数量：3 座火山、1 朵玫瑰、很多猴面包树
const VOLCANO_COUNT: int = 3
const ROSE_COUNT: int = 1
const BAOBAB_COUNT: int = 28

## 固定世界种子，保证地形与地物布局可复现（便于自动化验证与美术调优）
const WORLD_SEED: int = 20260817

## 火山之间的最小「环面距离」（格），保证 3 座火山足够分散
const VOLCANO_MIN_DISTANCE: float = 9.0
## 猴面包树之间的最小「环面距离」（格），避免过度堆叠
const BAOBAB_MIN_DISTANCE: float = 1.8

## 玩家移动速度（像素/秒）
const PLAYER_SPEED: float = 120.0

## SubViewport 渲染边长：等于世界像素边长即可完整覆盖整张地图。
## 边缘地物通过 3×3 环绕副本伸入视口，保证球面采样时 seam 不可见。
const VIEWPORT_PIXELS: int = WORLD_PIXELS
