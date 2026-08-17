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
## 地物改由屏幕叠加层绘制，视口内仅地面 + 小王子（小王子仍用 3×3 幽灵）。
const VIEWPORT_PIXELS: int = WORLD_PIXELS

## ---------- Stacked-sprite 伪 3D 地物（屏幕空间叠加） ----------
## 层数（底→顶）与世界 pitch（贴图像素）。实际凸出在 PropScreenOverlay 用屏幕 pitch。
const ROSE_LAYER_COUNT: int = 7
const BAOBAB_LAYER_COUNT: int = 9
const VOLCANO_LAYER_COUNT: int = 11

const ROSE_PITCH: float = 1.0
const BAOBAB_PITCH: float = 1.2
const VOLCANO_PITCH: float = 1.5

## 世界 pitch → 屏幕像素的额外放大：边缘顶层需明显戳出单位圆（r>1）
const STACK_SCREEN_PITCH_SCALE: float = 1.35

## 与 shader 默认一致，供测试 / 无材质时回退
const SHADER_DEFAULT_CURVATURE: float = 1.55
const SHADER_DEFAULT_VIEW_SPAN: float = 0.48
